from django.urls import path
from . import views
from rest_framework.urlpatterns import format_suffix_patterns

urlpatterns = [
    path('api/model/', views.SecurityModelAPIView.as_view(), name='security_model'),
    path('api/analyze/', views.AnalyzeAPIView.as_view(), name='analyze'),
    path('', views.upload_file, name='upload_file'),
    path('report/<str:file_id>/', views.view_report, name='view_report'),
    path('delete/<str:file_id>/', views.delete_file, name='delete_file'),
]

urlpatterns = format_suffix_patterns(urlpatterns) 