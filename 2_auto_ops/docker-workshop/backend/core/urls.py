from django.contrib import admin
from django.urls import path, include
from rest_framework.routers import DefaultRouter
from api.views import TodoViewSet

# สร้าง Router อัตโนมัติสำหรับ ViewSet
router = DefaultRouter()
router.register(r'todos', TodoViewSet)

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/', include(router.urls)), # URL เริ่มต้นสำหรับ API Todo
]
