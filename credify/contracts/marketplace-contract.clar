;; Freelancer Marketplace Contract
;; A system for freelancers to build reputation, showcase projects, and client testimonials

;; Error codes
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-FREELANCER-NOT-FOUND (err u101))
(define-constant ERR-ALREADY-ENDORSED (err u102))
(define-constant ERR-INVALID-PRIVACY-LEVEL (err u103))
(define-constant ERR-CERTIFICATION-NOT-FOUND (err u104))

;; Privacy levels
(define-constant PRIVACY-PUBLIC u0)
(define-constant PRIVACY-NETWORK-MEMBERS u1)
(define-constant PRIVACY-PRIVATE u2)

;; Data structures
(define-map freelancer-profiles
  principal
  {
    freelancer-name: (string-ascii 50),
    bio: (string-ascii 500),
    skills-summary: (string-ascii 200),
    privacy-level: uint,
    joined-at: uint,
    is-verified: bool
  })

(define-map project-portfolio
  { freelancer: principal, project-id: uint }
  {
    project-name: (string-ascii 100),
    client-company: (string-ascii 100),
    start-date: uint,
    end-date: (optional uint),
    project-description: (string-ascii 500),
    privacy-level: uint
  })

(define-map skill-certifications
  { freelancer: principal, certification-id: uint }
  {
    skill-name: (string-ascii 100),
    certifying-body: (string-ascii 100),
    issue-date: uint,
    expiry-date: (optional uint),
    certification-url: (string-ascii 200),
    privacy-level: uint,
    is-verified: bool
  })

(define-map client-testimonials
  { client: principal, freelancer: principal, skill: (string-ascii 50) }
  {
    testimonial: (string-ascii 200),
    timestamp: uint,
    is-public: bool
  })

(define-map professional-connections
  { freelancer1: principal, freelancer2: principal }
  {
    status: (string-ascii 20), ;; "pending", "accepted", "blocked"
    initiated-by: principal,
    timestamp: uint
  })

;; Counters for unique IDs
(define-data-var project-id-counter uint u0)
(define-data-var certification-id-counter uint u0)

;; Contract owner
(define-data-var contract-owner principal tx-sender)

;; Freelancer profile management functions
(define-public (create-freelancer-profile (freelancer-name (string-ascii 50)) (bio (string-ascii 500)) (skills-summary (string-ascii 200)) (privacy-level uint))
  (begin
    (asserts! (<= privacy-level PRIVACY-PRIVATE) ERR-INVALID-PRIVACY-LEVEL)
    (ok (map-set freelancer-profiles tx-sender {
      freelancer-name: freelancer-name,
      bio: bio,
      skills-summary: skills-summary,
      privacy-level: privacy-level,
      joined-at: block-height,
      is-verified: false
    }))))

(define-public (update-freelancer-profile (freelancer-name (string-ascii 50)) (bio (string-ascii 500)) (skills-summary (string-ascii 200)) (privacy-level uint))
  (begin
    (asserts! (<= privacy-level PRIVACY-PRIVATE) ERR-INVALID-PRIVACY-LEVEL)
    (asserts! (is-some (map-get? freelancer-profiles tx-sender)) ERR-FREELANCER-NOT-FOUND)
    (ok (map-set freelancer-profiles tx-sender {
      freelancer-name: freelancer-name,
      bio: bio,
      skills-summary: skills-summary,
      privacy-level: privacy-level,
      joined-at: (default-to block-height (get joined-at (map-get? freelancer-profiles tx-sender))),
      is-verified: (default-to false (get is-verified (map-get? freelancer-profiles tx-sender)))
    }))))

;; Project portfolio functions
(define-public (add-project-to-portfolio (project-name (string-ascii 100)) (client-company (string-ascii 100)) (start-date uint) (end-date (optional uint)) (project-description (string-ascii 500)) (privacy-level uint))
  (let ((project-id (+ (var-get project-id-counter) u1)))
    (begin
      (asserts! (<= privacy-level PRIVACY-PRIVATE) ERR-INVALID-PRIVACY-LEVEL)
      (asserts! (is-some (map-get? freelancer-profiles tx-sender)) ERR-FREELANCER-NOT-FOUND)
      (var-set project-id-counter project-id)
      (ok (map-set project-portfolio { freelancer: tx-sender, project-id: project-id } {
        project-name: project-name,
        client-company: client-company,
        start-date: start-date,
        end-date: end-date,
        project-description: project-description,
        privacy-level: privacy-level
      })))))

;; Skill certification functions
(define-public (add-skill-certification (skill-name (string-ascii 100)) (certifying-body (string-ascii 100)) (issue-date uint) (expiry-date (optional uint)) (certification-url (string-ascii 200)) (privacy-level uint))
  (let ((certification-id (+ (var-get certification-id-counter) u1)))
    (begin
      (asserts! (<= privacy-level PRIVACY-PRIVATE) ERR-INVALID-PRIVACY-LEVEL)
      (asserts! (is-some (map-get? freelancer-profiles tx-sender)) ERR-FREELANCER-NOT-FOUND)
      (var-set certification-id-counter certification-id)
      (ok (map-set skill-certifications { freelancer: tx-sender, certification-id: certification-id } {
        skill-name: skill-name,
        certifying-body: certifying-body,
        issue-date: issue-date,
        expiry-date: expiry-date,
        certification-url: certification-url,
        privacy-level: privacy-level,
        is-verified: false
      })))))

(define-public (verify-skill-certification (freelancer principal) (certification-id uint))
  (let ((certification (map-get? skill-certifications { freelancer: freelancer, certification-id: certification-id })))
    (begin
      (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)
      (asserts! (is-some certification) ERR-CERTIFICATION-NOT-FOUND)
      (ok (map-set skill-certifications { freelancer: freelancer, certification-id: certification-id }
        (merge (unwrap-panic certification) { is-verified: true }))))))

;; Client testimonial functions
(define-public (provide-client-testimonial (freelancer principal) (skill (string-ascii 50)) (testimonial (string-ascii 200)) (is-public bool))
  (begin
    (asserts! (is-some (map-get? freelancer-profiles tx-sender)) ERR-FREELANCER-NOT-FOUND)
    (asserts! (is-some (map-get? freelancer-profiles freelancer)) ERR-FREELANCER-NOT-FOUND)
    (asserts! (is-none (map-get? client-testimonials { client: tx-sender, freelancer: freelancer, skill: skill })) ERR-ALREADY-ENDORSED)
    (ok (map-set client-testimonials { client: tx-sender, freelancer: freelancer, skill: skill } {
      testimonial: testimonial,
      timestamp: block-height,
      is-public: is-public
    }))))

;; Professional connection functions
(define-public (send-networking-request (to-freelancer principal))
  (begin
    (asserts! (is-some (map-get? freelancer-profiles tx-sender)) ERR-FREELANCER-NOT-FOUND)
    (asserts! (is-some (map-get? freelancer-profiles to-freelancer)) ERR-FREELANCER-NOT-FOUND)
    (ok (map-set professional-connections { freelancer1: tx-sender, freelancer2: to-freelancer } {
      status: "pending",
      initiated-by: tx-sender,
      timestamp: block-height
    }))))

(define-public (accept-networking-request (from-freelancer principal))
  (let ((connection (map-get? professional-connections { freelancer1: from-freelancer, freelancer2: tx-sender })))
    (begin
      (asserts! (is-some connection) ERR-FREELANCER-NOT-FOUND)
      (asserts! (is-eq (get status (unwrap-panic connection)) "pending") ERR-NOT-AUTHORIZED)
      (ok (map-set professional-connections { freelancer1: from-freelancer, freelancer2: tx-sender }
        (merge (unwrap-panic connection) { status: "accepted" }))))))

;; Read-only functions with privacy controls
(define-read-only (get-freelancer-profile (freelancer principal))
  (let ((profile (map-get? freelancer-profiles freelancer)))
    (if (is-some profile)
      (let ((profile-data (unwrap-panic profile)))
        (if (or (is-eq (get privacy-level profile-data) PRIVACY-PUBLIC)
                (is-eq freelancer tx-sender)
                (is-professionally-connected freelancer tx-sender))
          profile
          none))
      none)))

(define-read-only (get-project-portfolio (freelancer principal) (project-id uint))
  (let ((project (map-get? project-portfolio { freelancer: freelancer, project-id: project-id })))
    (if (is-some project)
      (let ((project-data (unwrap-panic project)))
        (if (can-view-freelancer-data freelancer (get privacy-level project-data))
          project
          none))
      none)))

(define-read-only (get-skill-certification (freelancer principal) (certification-id uint))
  (let ((certification (map-get? skill-certifications { freelancer: freelancer, certification-id: certification-id })))
    (if (is-some certification)
      (let ((certification-data (unwrap-panic certification)))
        (if (can-view-freelancer-data freelancer (get privacy-level certification-data))
          certification
          none))
      none)))

(define-read-only (get-client-testimonial (client principal) (freelancer principal) (skill (string-ascii 50)))
  (let ((testimonial (map-get? client-testimonials { client: client, freelancer: freelancer, skill: skill })))
    (if (is-some testimonial)
      (let ((testimonial-data (unwrap-panic testimonial)))
        (if (or (get is-public testimonial-data)
                (is-eq freelancer tx-sender)
                (is-professionally-connected freelancer tx-sender))
          testimonial
          none))
      none)))

;; Helper functions
(define-read-only (is-professionally-connected (freelancer1 principal) (freelancer2 principal))
  (or (is-eq (get status (default-to { status: "none", initiated-by: freelancer1, timestamp: u0 } 
                          (map-get? professional-connections { freelancer1: freelancer1, freelancer2: freelancer2 }))) "accepted")
      (is-eq (get status (default-to { status: "none", initiated-by: freelancer2, timestamp: u0 } 
                          (map-get? professional-connections { freelancer1: freelancer2, freelancer2: freelancer1 }))) "accepted")))

(define-read-only (can-view-freelancer-data (data-owner principal) (privacy-level uint))
  (or (is-eq privacy-level PRIVACY-PUBLIC)
      (is-eq data-owner tx-sender)
      (and (is-eq privacy-level PRIVACY-NETWORK-MEMBERS) (is-professionally-connected data-owner tx-sender))))

;; Admin functions
(define-public (verify-freelancer-profile (freelancer principal))
  (let ((profile (map-get? freelancer-profiles freelancer)))
    (begin
      (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)
      (asserts! (is-some profile) ERR-FREELANCER-NOT-FOUND)
      (ok (map-set freelancer-profiles freelancer
        (merge (unwrap-panic profile) { is-verified: true }))))))

(define-public (set-contract-owner (new-owner principal))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)
    (ok (var-set contract-owner new-owner))))