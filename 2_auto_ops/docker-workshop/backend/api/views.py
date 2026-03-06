from rest_framework import viewsets
from rest_framework import serializers
from .models import Todo

# 1. Serializer (แปลง Data เป็น JSON)
class TodoSerializer(serializers.ModelSerializer):
    class Meta:
        model = Todo
        fields = '__all__'

# 2. ViewSet (จัดการ GET, POST, PUT, DELETE ให้ครบ)
class TodoViewSet(viewsets.ModelViewSet):
    queryset = Todo.objects.all().order_by('-created_at')
    serializer_class = TodoSerializer
