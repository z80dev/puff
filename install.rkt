#lang racket

(require racket/system
         racket/path
         racket/port
         pkg/lib)

;; Utility function to expand path with ~ for home directory
(define (expand-user-path path-str)
  (if (and (string? path-str)
           (> (string-length path-str) 0)
           (char=? (string-ref path-str 0) #\~))
      (build-path (find-system-path 'home-dir)
                 (substring path-str 2))
      path-str))

;; Function to check if a path is in PATH
(define (directory-in-path? dir)
  (let ([path-dirs (string-split (getenv "PATH") ":")])
    (member (path->string (simplify-path (expand-user-path dir)))
           (map (λ (p) (path->string (simplify-path (expand-user-path p))))
                path-dirs))))

(define (pkg-installed? pkg-name)
  (member pkg-name (installed-pkg-names)))

(define (install-if-missing pkg-name)
  (unless (pkg-installed? pkg-name)
    (let ([desc (pkg-desc pkg-name 'name pkg-name #f #f)])
      (printf "Installing Racket library: ~a...\n" pkg-name)
      (parameterize ([current-output-port (open-output-file "/dev/null" #:exists 'append)])
       (with-pkg-lock
        (pkg-install (list desc)))))))

;; Main installation function
(define (main)
  ;; Set up ~/.puff/builds directory structure
  (define puff-dir (expand-user-path "~/.puff"))
  (define builds-dir (build-path puff-dir "builds"))
  (define latest-build-dir (build-path builds-dir "latest"))

  ;; Create directories if they don't exist
  (make-directory* builds-dir)

  ;; Remove old latest build if it exists
  (when (directory-exists? latest-build-dir)
    (printf "Removing previous build...\n")
    (delete-directory/files latest-build-dir))

  ;; Check for "threading-lib" and "brag"
  (install-if-missing "threading-lib")
  (install-if-missing "brag")

  ;; First build the executable
  (printf "Building executable...\n")
  (unless (system "raco exe -o puffc main.rkt")
    (error "Failed to build executable"))

  ;; Create distribution in the builds directory
  (printf "Creating distribution...\n")
  (unless (system (format "raco distribute ~a puffc"
                         (path->string latest-build-dir)))
    (error "Failed to create distribution"))

  ;; Get the absolute path to the executable
  (define exe-path (simplify-path (build-path latest-build-dir "bin" "puffc")))

  ;; Prompt for installation directory
  (displayln "Where would you like to install the puffc executable?\n")
  (displayln "Common locations: ~/.local/bin, /usr/local/bin\n")
  (displayln "Default: ~/.local/bin\n")
  (printf "Installation directory: ")
  (flush-output)

  (define install-dir-str (let ([input (read-line)])
                           (if (string=? input "")
                               "~/.local/bin"
                               input)))

  (define install-dir (expand-user-path install-dir-str))

  ;; Create the installation directory if it doesn't exist
  (when (not (directory-exists? install-dir))
    (printf "Directory ~a doesn't exist. Create it? [y/N] " install-dir-str)
    (flush-output)
    (when (member (read-line) '("y" "Y" "yes" "Yes"))
      (make-directory* install-dir)))

  ;; Check if the directory exists now (after potential creation)
  (unless (directory-exists? install-dir)
    (error "Installation directory does not exist: ~a" install-dir))

  ;; Check if the directory is in PATH
  (unless (directory-in-path? install-dir)
    (printf "Warning: ~a is not in your PATH. You may need to add it.\n" install-dir-str))

  ;; Create the symlink path
  (define link-path (build-path install-dir "puffc"))

  ;; Remove existing symlink if it exists
  (when (file-exists? link-path)
    (printf "An existing puffc installation was found. Replace it? [y/N] ")
    (flush-output)
    (if (member (read-line) '("y" "Y" "yes" "Yes"))
        (delete-file link-path)
        (error "Installation cancelled")))

  ;; Create the symlink
  (make-file-or-directory-link (path->string exe-path) link-path)

  ;; Remove unneeded ./puffc file (used to build the distribution)
  (delete-file "./puffc")

  (printf "Installation complete!\n")
  (printf "puffc has been installed to ~a\n" link-path)
  (printf "Build files are located at ~a\n" latest-build-dir)

  ;; Provide helpful message if directory is not in PATH
  (unless (directory-in-path? install-dir)
    (printf "\nTo complete installation, add this line to your shell configuration file (~/.bashrc, ~/.zshrc, etc.):\n")
    (printf "export PATH=\"~a:$PATH\"\n" (path->string install-dir))))

;; Run the installation
(main)
