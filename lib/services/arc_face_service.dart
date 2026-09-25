// Conditional export: Native TFLite on mobile/desktop, web-friendly stub on web browsers
export 'arc_face_service_web.dart'
    if (dart.library.io) 'arc_face_service_io.dart';
