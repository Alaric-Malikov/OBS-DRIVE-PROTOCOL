import os
import mimetypes
import shutil
from pathlib import Path
from django.conf import settings
from django.http import (
    JsonResponse, FileResponse, Http404, HttpResponseBadRequest
)
from django.shortcuts import render, redirect
from django.views.decorators.http import require_POST, require_GET
from django.views.decorators.csrf import csrf_exempt

DRIVE_ROOT = Path(settings.DRIVE_ROOT).resolve()


def safe_path(subpath: str) -> Path:
    """Resolve a user-supplied subpath within DRIVE_ROOT. Raises Http404 if escape attempted."""
    if subpath:
        target = (DRIVE_ROOT / subpath).resolve()
    else:
        target = DRIVE_ROOT
    # Prevent path traversal
    try:
        target.relative_to(DRIVE_ROOT)
    except ValueError:
        raise Http404("Access denied.")
    return target


def file_info(path: Path, base: Path) -> dict:
    stat = path.stat()
    rel = path.relative_to(base)
    mime, _ = mimetypes.guess_type(str(path))
    is_previewable = mime and (
        mime.startswith('image/') or
        mime.startswith('text/') or
        mime == 'application/pdf' or
        mime.startswith('video/') or
        mime.startswith('audio/')
    )
    return {
        'name': path.name,
        'rel_path': str(rel).replace('\\', '/'),
        'is_dir': path.is_dir(),
        'size': stat.st_size if path.is_file() else None,
        'size_human': human_size(stat.st_size) if path.is_file() else '',
        'modified': stat.st_mtime,
        'mime': mime or '',
        'previewable': is_previewable,
        'ext': path.suffix.lower(),
    }


def human_size(n: int) -> str:
    for unit in ('B', 'KB', 'MB', 'GB', 'TB'):
        if n < 1024:
            return f"{n:.1f} {unit}" if unit != 'B' else f"{n} B"
        n /= 1024
    return f"{n:.1f} PB"


def breadcrumbs(subpath: str) -> list:
    crumbs = [{'name': 'Drive Root', 'path': ''}]
    if subpath:
        parts = Path(subpath).parts
        accumulated = ''
        for part in parts:
            accumulated = (accumulated + '/' + part).lstrip('/')
            crumbs.append({'name': part, 'path': accumulated})
    return crumbs


@require_GET
def browse(request, subpath=''):
    current_dir = safe_path(subpath)
    if not current_dir.exists() or not current_dir.is_dir():
        raise Http404("Directory not found.")

    sort_by = request.GET.get('sort', 'name')
    order = request.GET.get('order', 'asc')
    search = request.GET.get('q', '').strip().lower()

    entries = []
    for entry in current_dir.iterdir():
        info = file_info(entry, DRIVE_ROOT)
        if search and search not in info['name'].lower():
            continue
        entries.append(info)

    reverse = (order == 'desc')
    if sort_by == 'size':
        entries.sort(key=lambda x: (x['is_dir'], x['size'] or 0), reverse=reverse)
    elif sort_by == 'modified':
        entries.sort(key=lambda x: (x['is_dir'], x['modified']), reverse=reverse)
    else:
        entries.sort(key=lambda x: (not x['is_dir'], x['name'].lower()), reverse=reverse if sort_by != 'name' else False)
        if sort_by == 'name' and reverse:
            dirs = [e for e in entries if e['is_dir']]
            files = [e for e in entries if not e['is_dir']]
            entries = sorted(dirs, key=lambda x: x['name'].lower(), reverse=True) + \
                      sorted(files, key=lambda x: x['name'].lower(), reverse=True)

    parent_path = ''
    if subpath:
        parent = Path(subpath).parent
        parent_path = '' if str(parent) == '.' else str(parent).replace('\\', '/')

    context = {
        'entries': entries,
        'subpath': subpath,
        'breadcrumbs': breadcrumbs(subpath),
        'parent_path': parent_path,
        'is_root': subpath == '',
        'sort_by': sort_by,
        'order': order,
        'search': search,
        'drive_root': str(DRIVE_ROOT),
    }
    return render(request, 'browser/index.html', context)


def download(request, subpath):
    target = safe_path(subpath)
    if not target.is_file():
        raise Http404("File not found.")
    response = FileResponse(open(target, 'rb'), as_attachment=True, filename=target.name)
    return response


def preview(request, subpath):
    target = safe_path(subpath)
    if not target.is_file():
        raise Http404("File not found.")
    mime, _ = mimetypes.guess_type(str(target))
    return FileResponse(open(target, 'rb'), content_type=mime or 'application/octet-stream')


@csrf_exempt
@require_POST
def upload(request):
    dest_path = request.POST.get('path', '')
    dest_dir = safe_path(dest_path)
    if not dest_dir.is_dir():
        return HttpResponseBadRequest("Invalid destination.")

    uploaded = []
    errors = []
    for f in request.FILES.getlist('files'):
        dest_file = dest_dir / f.name
        try:
            with open(dest_file, 'wb') as out:
                for chunk in f.chunks():
                    out.write(chunk)
            uploaded.append(f.name)
        except Exception as e:
            errors.append({'name': f.name, 'error': str(e)})

    return JsonResponse({'uploaded': uploaded, 'errors': errors})


@csrf_exempt
@require_POST
def delete(request):
    import json
    data = json.loads(request.body)
    paths = data.get('paths', [])
    errors = []
    for p in paths:
        try:
            target = safe_path(p)
            if target.is_dir():
                shutil.rmtree(target)
            elif target.is_file():
                target.unlink()
        except Exception as e:
            errors.append({'path': p, 'error': str(e)})
    return JsonResponse({'ok': len(errors) == 0, 'errors': errors})


@csrf_exempt
@require_POST
def rename(request):
    import json
    data = json.loads(request.body)
    old_path = data.get('path', '')
    new_name = data.get('new_name', '').strip()
    if not new_name or '/' in new_name or '\\' in new_name:
        return HttpResponseBadRequest("Invalid name.")
    target = safe_path(old_path)
    new_target = target.parent / new_name
    try:
        target.rename(new_target)
    except Exception as e:
        return JsonResponse({'ok': False, 'error': str(e)}, status=400)
    return JsonResponse({'ok': True})


@csrf_exempt
@require_POST
def new_folder(request):
    import json
    data = json.loads(request.body)
    parent_path = data.get('path', '')
    folder_name = data.get('name', '').strip()
    if not folder_name or '/' in folder_name or '\\' in folder_name:
        return HttpResponseBadRequest("Invalid folder name.")
    parent = safe_path(parent_path)
    new_dir = parent / folder_name
    try:
        new_dir.mkdir(parents=False, exist_ok=False)
    except FileExistsError:
        return JsonResponse({'ok': False, 'error': 'Folder already exists.'}, status=400)
    except Exception as e:
        return JsonResponse({'ok': False, 'error': str(e)}, status=400)
    return JsonResponse({'ok': True})
