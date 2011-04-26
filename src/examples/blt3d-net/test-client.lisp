(ql:quickload :blackthorn3d)
(in-package :blt3d-net)
(defvar *port* 12345)
(let ((server (socket-client-connect "localhost" *port* :timeout 10)))
  (if server
      (format t "Connected to server ~a.~%" server)
      (blt3d-main::exit)))
(defvar *my-buffer* (make-buffer))
(serialize :string "Hello world!" :buffer *my-buffer*)
(socket-message-send :server *my-buffer*)
(blt3d-main::exit)