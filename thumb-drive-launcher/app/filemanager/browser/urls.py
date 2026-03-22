from django.urls import path
from . import views

urlpatterns = [
    path('', views.browse, name='browse'),
    path('browse/', views.browse, name='browse_root'),
    path('browse/<path:subpath>/', views.browse, name='browse_path'),
    path('download/<path:subpath>', views.download, name='download'),
    path('upload/', views.upload, name='upload'),
    path('delete/', views.delete, name='delete'),
    path('rename/', views.rename, name='rename'),
    path('newfolder/', views.new_folder, name='new_folder'),
    path('preview/<path:subpath>', views.preview, name='preview'),
]
