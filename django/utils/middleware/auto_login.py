from django.contrib.auth.models import User
from django.contrib import auth


def auto_login(get_response):

    def middleware(request):
        if request.user.is_authenticated:
            return get_response(request)
        if not request.path_info.startswith('/admin'):
            return get_response(request)

        try:
            User.objects.create_superuser('admin', 'admin@example.com', 'admin')
        except:
            pass

        user = auth.authenticate(username='admin', password='admin')
        if user:
            request.user = user
            auth.login(request, user)

        return get_response(request)
    return middleware
