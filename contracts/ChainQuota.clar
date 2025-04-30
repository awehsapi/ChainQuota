;; ChainQuota - Resource Allocation Smart Contract

;; Error Constants
(define-constant CONTRACT_ADMINISTRATOR tx-sender)
(define-constant ERROR_UNAUTHORIZED_ACCESS (err u100))
(define-constant ERROR_INVALID_RESOURCE_QUANTITY (err u101))
(define-constant ERROR_INSUFFICIENT_RESOURCE_BALANCE (err u102))
(define-constant ERROR_RESOURCE_TYPE_NOT_FOUND (err u103))
(define-constant ERROR_CONTRACT_ALREADY_INITIALIZED (err u104))
(define-constant ERROR_INVALID_RECIPIENT (err u105))
(define-constant ERROR_RESOURCE_ALLOCATION_EXCEEDED (err u106))
(define-constant ERROR_INSUFFICIENT_PRIORITY (err u107))
(define-constant ERROR_RESOURCE_FROZEN (err u108))
(define-constant ERROR_REQUEST_TIMEOUT (err u109))
(define-constant ERROR_INVALID_PARAMETERS (err u110))

;; Data Variables
(define-data-var is-contract-initialized bool false)
(define-data-var pending-request-counter uint u0)
(define-data-var is-system-frozen bool false)
(define-data-var is-maintenance-active bool false)
(define-data-var global-allocation-limit uint u1000000)
(define-data-var backup-admin-address principal CONTRACT_ADMINISTRATOR)

;; Data Maps
(define-map user-resource-balances principal uint)
(define-map available-resource-types uint {
    resource-name: (string-ascii 64),
    total-supply: uint,
    available-supply: uint,
    unit-price: uint,
    is-frozen: bool,
    min-access-level: uint,
    min-allocation: uint,
    max-allocation: uint,
    freeze-duration: uint,
    last-price-update: uint
})

(define-map allocation-requests uint {
    requester: principal,
    requested-amount: uint,
    resource-type: uint,
    request-status: (string-ascii 20),
    requester-priority: uint,
    request-timestamp: uint,
    expiration-timestamp: uint,
    request-reason: (string-ascii 128)
})

(define-map user-allocation-history principal (list 10 uint))
(define-map resource-price-history uint (list 10 uint))
(define-map user-access-levels principal (string-ascii 20))
(define-map blocked-accounts principal bool)
(define-map resource-dependencies uint (list 5 uint))

;; Private Functions
(define-private (is-admin)
    (is-eq tx-sender CONTRACT_ADMINISTRATOR)
)

(define-private (is-quantity-valid (requested-amount uint))
    (and 
        (> requested-amount u0)
        (<= requested-amount (var-get global-allocation-limit))
    )
)

(define-private (resource-exists (resource-id uint))
    (is-some (map-get? available-resource-types resource-id))
)

(define-private (is-user-authorized (user-address principal))
    (and
        (not (default-to false (map-get? blocked-accounts user-address)))
        (>= (get-user-priority-level user-address) u1)
    )
)

(define-private (get-user-priority-level (user-address principal))
    (let ((user-role (default-to "USER" (map-get? user-access-levels user-address))))
        (if (is-eq user-role "ADMIN")
            u5
            (if (is-eq user-role "PREMIUM")
                u4
                (if (is-eq user-role "BUSINESS")
                    u3
                    (if (is-eq user-role "VERIFIED")
                        u2
                        u1)))))) ;; Default USER level

(define-private (update-price-history-log (resource-id uint) (new-price uint))
    (let (
        (price-history (default-to (list) (map-get? resource-price-history resource-id)))
        (updated-history (unwrap! (as-max-len? (concat (list new-price) price-history) u10) (err u0)))
    )
        (ok (map-set resource-price-history resource-id updated-history))
    )
)

(define-private (is-valid-user-address (user-address principal))
    (is-standard user-address)
)
