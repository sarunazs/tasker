from django.http import HttpResponse


def landing(request):
    return HttpResponse("tasker is alive", content_type="text/plain")
