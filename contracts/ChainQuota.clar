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

;; Read Only Functions
(define-read-only (get-user-balance (user-address principal))
    (default-to u0 (map-get? user-resource-balances user-address))
)

(define-read-only (get-resource-info (resource-id uint))
    (map-get? available-resource-types resource-id)
)

(define-read-only (get-request-details (request-id uint))
    (map-get? allocation-requests request-id)
)

(define-read-only (get-user-allocation-history (user-address principal))
    (default-to (list) (map-get? user-allocation-history user-address))
)

(define-read-only (get-resource-price-history (resource-id uint))
    (default-to (list) (map-get? resource-price-history resource-id))
)

(define-read-only (get-system-status)
    {
        initialized: (var-get is-contract-initialized),
        paused: (var-get is-system-frozen),
        maintenance: (var-get is-maintenance-active),
        global-limit: (var-get global-allocation-limit),
        emergency-contact: (var-get backup-admin-address)
    }
)

;; Public Functions
;; System Management Functions
(define-public (initialize-system)
    (begin
        (asserts! (is-admin) ERROR_UNAUTHORIZED_ACCESS)
        (asserts! (not (var-get is-contract-initialized)) ERROR_CONTRACT_ALREADY_INITIALIZED)
        (var-set is-contract-initialized true)
        (var-set pending-request-counter u0)
        (var-set is-system-frozen false)
        (var-set is-maintenance-active false)
        (ok true)
    )
)

(define-public (update-system-parameters (new-global-limit uint) (new-backup-admin principal))
    (begin
        (asserts! (is-admin) ERROR_UNAUTHORIZED_ACCESS)
        (asserts! (> new-global-limit u0) ERROR_INVALID_PARAMETERS)
        (asserts! (is-valid-user-address new-backup-admin) ERROR_INVALID_PARAMETERS)
        (var-set global-allocation-limit new-global-limit)
        (var-set backup-admin-address new-backup-admin)
        (ok true)
    )
)

;; Resource Management Functions
(define-public (register-resource-type 
    (resource-id uint) 
    (resource-name (string-ascii 64)) 
    (initial-supply uint) 
    (initial-price uint)
    (min-allocation uint)
    (max-allocation uint)
    (required-priority uint))
    (begin
        (asserts! (is-admin) ERROR_UNAUTHORIZED_ACCESS)
        (asserts! (is-quantity-valid initial-supply) ERROR_INVALID_RESOURCE_QUANTITY)
        (asserts! (is-quantity-valid initial-price) ERROR_INVALID_RESOURCE_QUANTITY)
        (asserts! (<= required-priority u5) ERROR_INSUFFICIENT_PRIORITY)
        (asserts! (>= min-allocation u1) ERROR_INVALID_PARAMETERS)
        (asserts! (> max-allocation min-allocation) ERROR_INVALID_PARAMETERS)
        (asserts! (<= max-allocation initial-supply) ERROR_INVALID_PARAMETERS)
        (asserts! (not (resource-exists resource-id)) ERROR_INVALID_PARAMETERS)
        (asserts! (>= (len resource-name) u1) ERROR_INVALID_PARAMETERS)

        (map-set available-resource-types resource-id {
            resource-name: resource-name,
            total-supply: initial-supply,
            available-supply: initial-supply,
            unit-price: initial-price,
            is-frozen: false,
            min-access-level: required-priority,
            min-allocation: min-allocation,
            max-allocation: max-allocation,
            freeze-duration: u0,
            last-price-update: block-height
        })
        (ok true)
    )
)

(define-public (update-resource-price (resource-id uint) (new-price uint))
    (let (
        (resource-info (unwrap! (map-get? available-resource-types resource-id) ERROR_RESOURCE_TYPE_NOT_FOUND))
    )
        (asserts! (is-admin) ERROR_UNAUTHORIZED_ACCESS)
        (asserts! (is-quantity-valid new-price) ERROR_INVALID_RESOURCE_QUANTITY)
        (asserts! (resource-exists resource-id) ERROR_RESOURCE_TYPE_NOT_FOUND)

        (try! (update-price-history-log resource-id new-price))

        (map-set available-resource-types resource-id 
            (merge resource-info {
                unit-price: new-price,
                last-price-update: block-height
            })
        )
        (ok true)
    )
)
