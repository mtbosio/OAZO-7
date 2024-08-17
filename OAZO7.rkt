#lang typed/racket

(require typed/rackunit)

;; ---------------- OAZO7 ----------------

;; Expr	 	=	 	Num
;; 	 	|	 	id
;; 	 	|	 	String
;; 	 	|	 	{id := Expr}
;; 	 	|	 	{if Expr then Expr else Expr}
;;	 	|	 	{let [[id : ty] <- Expr] ... Expr}
;;	 	|	 	{anon {[ty id] ...} : Expr}
;; 	 	|	 	{seq Expr ...}
;; 	 	|	 	{Expr Expr ...}
;; ty	 	=	 	num
;; 	 	|	 	bool
;; 	 	|	 	str
;; 	 	|	 	void
;; 	 	|	 	{ty ... -> ty}
;; 	 	|	 	numarray
;; operator	=	 	+
;; 	 	|	 	-
;; 	 	|	 	*
;; 	 	|	 	/
;; 	 	|	 	num-eq?
;; 	 	|	 	str-eq?
;; 	 	|	 	<=
;; 	 	|	 	substring
;; 	 	|	 	arr
;; 	 	|	 	aref
;; 	 	|	 	aset
;; 	 	|	 	alen

;; where an id is not let, :=, if, then, else, :, <-, seq

;; Values
(define-type Value(U Real ClosV Boolean String PrimopV ArrayV NullV))
(struct ClosV([args : (Listof Symbol)] [body : ExprC] [env : Env]) #:transparent)
(struct PrimopV([func : (-> (Listof Value) Store Result)]) #:transparent)
(struct ArrayV([head : Location] [length : Real]) #:transparent)
(struct NullV() #:transparent)

;; EXPR
(define-type ExprC(U NumC IdC AppC IfC LamC StringC SeqC MutC))
(struct LamC([args : (Listof Symbol)] [body : ExprC] [types : (Listof Type)]) #:transparent)
(struct NumC([n : Real]) #:transparent)
(struct StringC([s : String]) #:transparent)
(struct IdC([s : Symbol]) #:transparent)
(struct AppC([fun : ExprC] [args : (Listof ExprC)]) #:transparent)
(struct IfC ([test : ExprC] [then : ExprC] [else : ExprC]) #:transparent)
(struct SeqC ([exprs : (Listof ExprC)]) #:transparent)
(struct MutC ([id : ExprC] [val : ExprC]) #:transparent)

;; Binding, Env, Store, Location, Result
(define-type-alias Location Real)
(struct Binding ((name : Symbol) (val : Location)) #:transparent) 
(define-type Env (Listof Binding))
(struct Cell ((location : Location) (val : Value)) #:transparent)
(define-type Store (Listof Cell))
(struct Result([value : Value] [store : Store]) #:transparent)

;; Types
(define-type Type (U NumT StrT FunT BoolT VoidT ArrayT))
(struct NumT() #:transparent)
(struct StrT() #:transparent)
(struct BoolT() #:transparent)
(struct VoidT() #:transparent)
(struct ArrayT() #:transparent)
(struct FunT([args-ty : (Listof Type)] [r-ty : Type]) #:transparent)
(struct type-binding ([name : Symbol] [type : Type]))
(define-type TEnv (Listof type-binding))

;; ----- Primop Functions -----

;; num+ - takes a and b and calculates a + b
;; (Inputs: (Listof Value) Store | Outputs: Result)
(define (num+ [vals : (Listof Value)] [store : Store]) : Result
  (define f (first vals))
  (define s (second vals))
  (cond [(real? f) (cond [(real? s) (Result (+ f s) store)]
                         [else (error '- "OAZO - ~a was not a number" s)])]
        [else (error '- "OAZO - ~a was not a number" f)]))

;; num- - takes a and b and calculates a - b
;; (Inputs: (Listof Value) Store | Outputs: Result)
(define (num- [vals : (Listof Value)] [store : Store]) : Result
  (define f (first vals))
  (define s (second vals))
  (cond [(real? f) (cond [(real? s) (Result (- f s) store)]
                         [else (error '* "OAZO - ~a was not a number" s)])]
        [else (error '* "OAZO - ~a was not a number" f)]))

;; num* - takes a and b and calculates a + b
;; (Inputs: (Listof Value) Store | Outputs: Result)
(define (num* [vals : (Listof Value)] [store : Store]) : Result
  (define f (first vals))
  (define s (second vals))
  (cond [(real? f) (cond [(real? s) (Result (* f s) store)]
                         [else (error '+ "OAZO - ~a was not a number" s)])]
        [else (error '* "OAZO - ~a was not a number" f)]))

;; num/ - takes a and b and calculates a + b
;; (Inputs: (Listof Value) Store | Outputs: Result)
(define (num/ [vals : (Listof Value)] [store : Store]) : Result
  (define f (first vals))
  (define s (second vals))
  (cond [(real? f) (cond [(real? s) (cond [(zero? s) (error '/ "OAZO - second arg cannot be zero")]
                                          [else (Result (/ f s) store)])]
                         [else (error '/ "OAZO - ~a was not a number" s)])]
        [else (error '/ "OAZO - ~a was not a number" f)]))

;; lteq - takes a and b and calculates a <= b
;; (Inputs: (Listof Value) Store | Outputs: Result)
(define (lteq [vals : (Listof Value)] [store : Store]) : Result
  (define f (first vals))
  (define s (second vals))
  (cond [(real? f) (cond [(real? s) (Result (<= f s) store)]
                         [else (error 'lteq "OAZO - ~a was not a number" s)])]
        [else (error 'lteq "OAZO - ~a was not a number" f)]))

;; num-eq? -Return true if a is equal to b and a and b are num
;; (Inputs: (Listof Value) Store | Outputs: Result)
(define (num-eq? [vals : (Listof Value)] [store : Store]) : Result
  (define f (first vals))
  (define s (second vals))
  (cond [(real? f) (cond [(real? s) (Result (equal? f s) store)]
                         [else (error 'num-eq? "OAZO - ~a was not a number" s)])]
        [else (error 'num-eq? "OAZO - ~a was not a number" f)]))

;; str-eq? -Return true if a is equal to b and a and b are strings
;; (Inputs: (Listof Value) Store | Outputs: Result)
(define (str-eq? [vals : (Listof Value)] [store : Store]) : Result
  (define f (first vals))
  (define s (second vals))
  (cond [(string? f) (cond [(string? s) (Result (equal? f s) store)]
                         [else (error 'str-eq? "OAZO - ~a was not a str" s)])]
        [else (error 'str-eq? "OAZO - ~a was not a str" f)]))

;; arr-eq? -Return true if a and b refer to the same array
;; (Inputs: (Listof Value) Store | Outputs: Result)
(define (arr-eq? [vals : (Listof Value)] [store : Store]) : Result
  (define f (first vals))
  (define s (second vals))
  (cond [(ArrayV? f) (cond [(ArrayV? s) (Result (equal? (ArrayV-head f) (ArrayV-head s)) store)]
                         [else (error 'arr-eq? "OAZO - ~a was not an array" s)])]
        [else (error 'arr-eq? "OAZO - ~a was not an array" f)]))

;; store-size? - returns size of the given store
;; (Inputs: Store | Outputs: Real)
(define (store-size? [store : Store]) : Real
  (length store))

;; allocate - given a store, a list of locations, and a default value, returns a pair containing
;; the starting location of a new array and a new store with the array
;; (Inputs: Store (Listof Location) Value | Outputs: (Pairof Location Store))
(define (allocate [store : Store] [locations : (Listof Location)] [value : Value]) : (Pairof Location Store)
  (cons (store-size? store) ((inst foldl Location Store Store) (λ ([item : Location] [result : Store])
                                                                 (cons (Cell item value) result)) store locations)))

;; arr - Return a new array of size size whose elements are all initially
;; set to default, which must be a number.
;; (Inputs: (Listof Value) Store | Outputs: Result)
(define (arr [vals : (Listof Value)] [store : Store]) : Result
  (define size (first vals))
  (define default (second vals))
  (cond [(and (real? size) (real? default) (> size 0))
         (define locations (range (store-size? store) (+ (store-size? store) size)))
         (define all (allocate store locations (second vals)))
         (Result (ArrayV (car all) size) (cdr all))]
        [else (error 'arr "OAZO - invalid arr syntax")]))


;; aref - Given an array and an index, return the value in the array at the given index.
;; (Inputs: (Listof Value) Store | Outputs: Result)
(define (aref [vals : (Listof Value)] [store : Store]) : Result
  (define arr (first vals))
  (define index (second vals))
  (cond [(ArrayV? arr) (define head (ArrayV-head arr))
                       (cond [(and (exact-integer? head) (exact-integer? index))
                              (Result (fetch (+ head index) store) store)]
                             [else (error 'aref "OAZO - invalid aref syntax")])]
        [else (error 'aref "OAZO - invalid aref syntax")]))

;; aset - Given an array and an index and a new value, mutate the array at the
;; given index to contain the new value, and return void
;; (Inputs: (Listof Value) Store | Outputs: Result)
(define (aset [vals : (Listof Value)] [store : Store]) : Result
  (define arr (first vals))
  (define index (second vals))
  (define new-value (third vals))
  (cond [(and (ArrayV? arr) (exact-integer? index) (exact-integer? new-value))
         (Result (NullV) (cons (Cell (+ (ArrayV-head arr) index) new-value) store))]
        [else (error 'aset "OAZO - invalid aset syntax")]))

;; alen - given an array and a store, return the length of the array
;; (Inputs: (Listof Value) Store | Outputs: Result)
(define (alen [vals : (Listof Value)] [store : Store]) : Result
  (define arr (first vals))
  (cond [(ArrayV? arr) (Result (ArrayV-length arr) store)]
        [else (error 'alen "OAZO - alen: not an array")]))

;; substring - accepts a string and a start and end position,
;; and returns the corresponding substring. 
(define (oazo-substring [vals : (Listof Value)] [store : Store]) : Result
  (define str (first vals))
  (define start (second vals))
  (define end (third vals))
  (cond [(string? str) (cond [(and (exact-integer? start) (exact-integer? end))
                              (Result (substring str start end) store)]
                             [else (error 'substring "OAZO - start and end are not numbers")])]
        [else (error 'substring "OAZO - ~a is not a string" str)])) 

;; top-env - starting environment
(define top-env (list
                      (Binding 'true 0)
                      (Binding 'false 1)
                      (Binding '+ 2)
                      (Binding '- 3)
                      (Binding '* 4)
                      (Binding '/ 5)
                      (Binding '<= 6)
                      (Binding 'num-eq? 7)
                      (Binding 'str-eq? 8)
                      (Binding 'arr-eq? 9)
                      (Binding 'arr 10)
                      (Binding 'aref 11)
                      (Binding 'aset 12)
                      (Binding 'alen 13)
                      (Binding 'substring 14)))

;; top-store - starting store
(define top-store (list
                   (Cell 14 (PrimopV oazo-substring))
                   (Cell 13 (PrimopV alen))
                   (Cell 12 (PrimopV aset))
                   (Cell 11 (PrimopV aref))
                   (Cell 10 (PrimopV arr))
                   (Cell 9 (PrimopV arr-eq?))
                   (Cell 8 (PrimopV str-eq?))
                   (Cell 7 (PrimopV num-eq?))
                   (Cell 6 (PrimopV lteq))
                   (Cell 5 (PrimopV num/))
                   (Cell 4 (PrimopV num*))
                   (Cell 3 (PrimopV num-))
                   (Cell 2 (PrimopV num+))
                   (Cell 1 #f)
                   (Cell 0 #t)))

;; base-tenv - starting type environment
(define base-tenv (list
                   (type-binding 'alen (FunT (list (ArrayT)) (NumT)))
                   (type-binding 'aset (FunT (list (ArrayT) (NumT) (NumT)) (VoidT)))
                   (type-binding 'aref (FunT (list (ArrayT) (NumT)) (NumT)))
                   (type-binding 'arr (FunT (list (NumT) (NumT)) (ArrayT)))
                   (type-binding 'arr-eq? (FunT (list (ArrayT) (ArrayT)) (BoolT)))
                   (type-binding 'str-eq? (FunT (list (StrT) (StrT)) (BoolT)))
                   (type-binding 'num-eq? (FunT (list (NumT) (NumT)) (BoolT)))
                   (type-binding '<= (FunT (list (NumT) (NumT)) (BoolT)))
                   (type-binding '/ (FunT (list (NumT) (NumT)) (NumT)))
                   (type-binding '* (FunT (list (NumT) (NumT)) (NumT)))
                   (type-binding '- (FunT (list (NumT) (NumT)) (NumT)))
                   (type-binding '+ (FunT (list (NumT) (NumT)) (NumT)))
                   (type-binding 'false (BoolT))
                   (type-binding 'true (BoolT))
                   ))

;; serialize - takes a value and returns the serialized string of it
;; (Inputs: Value | Outputs: String)
(define (serialize [val : Value] [store : Store]) : String
  (match val
    [(? real? a) (~v a)]
    [(? boolean? a) (cond [a "true"]
                          [else "false"])]
    [(? string? a) (~v a)]
    [(ClosV a b c) "#<procedure>"]
    [(PrimopV a) "#<primop>"]
    [(ArrayV head size) "#<array>"]
    [(NullV) "null"]))

;; check-id - returns true if a symbol matches any of the disallowed id names
;; (Inputs: Symbol | Outputs: Boolean)
(define (check-id [name : Symbol]) : Boolean
  (or (equal? name 'if) (equal? name 'then) (equal? name 'else)
      (equal? name 'let) (equal? name 'anon) (equal? name ':)
      (equal? name '<-) (equal? name 'seq) (equal? name ':=)))

;; lookup-type - given a symbol, returns the location of it in the store
;; (Inputs: Symbol Env | Outputs: Location)
(define (lookup-type [for : Symbol] [env : TEnv]) : Type
    (match env
      ['() (error 'lookup "OAZO - ~e is not defined" for)]
      [(cons (type-binding name type) r) (cond
                    [(symbol=? for name) type]
                    [else (lookup-type for r)])]))

;; parse-type - parses a type
(define (parse-type [s : Sexp]) : Type
  (match s
    ['num (NumT)]
    ['str (StrT)]
    ['bool (BoolT)]
    ['void (VoidT)]
    ['numarray (ArrayT)]
    [(list args ... '-> return) (FunT ((inst map Type Sexp) parse-type (cast args (Listof Sexp)))
                                      (parse-type return))]))

;; type-check - type-check an expression
(define (type-check [e : ExprC] [env : TEnv]) : Type
  (match e
    [(NumC n) (NumT)]
    [(StringC s) (StrT)]
    [(IdC s) (lookup-type s env)]
    [(LamC args body types) ;; extend type env
     (define extended-env (foldl (λ([arg : Symbol] [type : Type] [result : TEnv]) : TEnv
                                   (cons (type-binding arg type) result)) env args types))
     (FunT types (type-check body extended-env))]
    ;;[(MutC id val) ()]
    [(AppC f a) (define arg-types (map (λ ([x : ExprC]) : Type (type-check x env)) a))
                (match (type-check f env)
                  [(FunT args return)
                   (cond [(equal? args arg-types) return]
                         [else (error 'type-check "OAZO - function argument types do not match input types")])]
                  )]
    [(IfC if then els) (cond [(BoolT? (type-check if env))
                              (define then-type (type-check then env))
                              (define els-type (type-check els env))
                              (cond [(equal? then-type els-type) then-type]
                                    [else (error 'type-check "OAZO - then and else have different types")])]
                             [else (error 'type-check "OAZO - ~v does not evaluate to a bool" (type-check if env))])]
    #;[(SeqC (? list? exprs)) ()]))

;; parse - parses an expression
;; (Inputs: Sexp | Outputs: ExprC)
(define (parse [s : Sexp]) : ExprC
  (match s
    [(? real? n) (NumC n)]
    [(? string? s) (StringC s)]
    [(? symbol? name) (cond [(not (check-id name)) (IdC name)]
                            [else (error 'parse "OAZO - invalid id name")])]
    [(list 'let (list (list args ': types) arrow values) ... body)
     (cond [(check-duplicates args) (error 'parse "OAZO - cannot have duplicate ids")]
           [else (AppC (LamC (cast args (Listof Symbol)) (parse body)
                             ((inst map Type Sexp) parse-type (cast types (Listof Sexp))))
                       (for/list : (Listof ExprC) ([item (cast values (Listof Sexp))]) (parse item)))])]
    [(list 'anon (list (list types (? symbol? args)) ...) ': body)
     (cond [(check-duplicates args) (error 'parse "OAZO - cannot have duplicate ids")]
           [(not (empty? (filter check-id (cast args (Listof Symbol))))) (error 'parse "OAZO - invalid id name")]
           [else (LamC (cast args (Listof Symbol)) (parse body)
                       ((inst map Type Sexp) parse-type (cast types (Listof Sexp))))])]
    [(list 'seq rst ...) (define seq-list (foldr
                                           (λ ([x : Sexp] [result : (Listof ExprC)]) (cons (parse x) result)) '() rst)) 
                         (SeqC seq-list)]
    [(list id ':= expr) (MutC (parse id) (parse expr))]
    [(list 'if test 'then then 'else else) (IfC (parse test) (parse then) (parse else))]
    [(list func args ...) (cond [(equal? func 'if) (error 'parse "OAZO - incomplete if statement")]
                      [else (AppC (parse func) (for/list : (Listof ExprC) ([item (cast args (Listof Sexp))])
                                                             (parse item)))])]
    [other (error 'parse "OAZO - parse error in: ~e" other)]))

;; interp - takes an ExprC and an environment and
;; returns the interpretted version of it
;; (Inputs: ExprC, Env Store | Outputs: Result)
(define (interp [ast : ExprC] [env : Env] [store : Store]) : Result
  (match ast
    [(NumC n) (Result n store)]
    [(IdC n) (Result (fetch (lookup n env) store) store)]
    [(StringC s) (Result s store)] 
    [(LamC a b c) (Result (ClosV a b env) store)]
    [(MutC id val) (cond [(IdC? id) (define id-result (interp id env store))
                                    (define location (lookup (IdC-s id) env))
                                    (define val-result (interp val env (Result-store id-result)))
                                    (Result (NullV) (cons (Cell location (Result-value val-result))
                                                          (Result-store val-result)))]
                         [else (error 'interp "OAZO - id was incorrect format")])]
    [(AppC f (? list? a)) (define name-result (interp f env store))
                          (match (Result-value name-result)
                            [(ClosV args body clos-env)
                             (cond [(equal? (length args) (length a))
                                    (define new-args ((inst map Value ExprC) (λ([x : ExprC]) : Value
                                                  (Result-value (interp x env (Result-store name-result)))) a))
                                    (define updated ((inst foldl Symbol Value (Pairof Env Store))
                                                     (λ ([id : Symbol] [value : Value] [result : (Pairof Env Store)])
                                                       (cons (cons (Binding id (store-size? (cdr result)))
                                                                   (car result))
                                                             (cons (Cell (store-size? (cdr result)) value)
                                                                   (cdr result))))
                                                     (cons clos-env (Result-store name-result)) args new-args))                    
                                    (interp body (car updated) (cdr updated))]
                                   [else (error 'interp "OAZO - wrong number of arguments provided")])]
                            [(PrimopV op) (match a
                                            [(list first second)
                                             (define l-result (interp first env (Result-store name-result)))
                                             (define r-result (interp second env (Result-store l-result)))
                                             (define op-result
                                               (op (list (Result-value l-result)
                                                         (Result-value r-result)) (Result-store r-result)))
                                             (Result (Result-value op-result) (Result-store op-result))]
                                            [(list first second third)
                                             (define f-result (interp first env store))
                                             (define s-result (interp second env (Result-store f-result)))
                                             (define t-result (interp third env (Result-store s-result)))
                                             (define op-result
                                               (op (list (Result-value f-result) (Result-value s-result)
                                                         (Result-value t-result)) (Result-store t-result)))
                                             (Result (Result-value op-result) (Result-store op-result))])]
                            [else (error 'interp "OAZO - invalid application")])]
    [(SeqC (? list? exprs)) (foldl (λ ([expr : ExprC] [result : Result]) (interp expr env (Result-store result)))
                                   (interp (first exprs) env store) (list-tail exprs 1))]   
    [(IfC test then els) (define test-result (interp test env store))
                         (cond [(boolean? (Result-value test-result))
                                (cond [(Result-value test-result) (interp then env (Result-store test-result))]
                                      [else (interp els env (Result-store test-result))])]
                               [else (error 'interp "OAZO - If test was not a boolean in expression")])]))

;; lookup - given a symbol, returns the location of it in the store
;; (Inputs: Symbol Env | Outputs: Location)
(define (lookup [for : Symbol] [env : Env]) : Location
    (match env
      ['() (error 'lookup "OAZO - ~e is not defined" for)]
      [(cons (Binding name loc) r) (cond
                    [(symbol=? for name) loc]
                    [else (lookup for r)])]))

;; fetch - given a location, return the value of the cell at that location
;; (Inputs: Location Store | Outputs: Value)
(define (fetch [for : Location] [store : Store]) : Value
  (match store
      ['() (error 'lookup "OAZO - ~e is not defined" for)]
      [(cons (Cell location value) r) (cond
                    [(equal? for location) value]
                    [else (fetch for r)])]))

;; top-interp - combines parsing and evaluation
;; (Inputs: Sexp | Outputs: String)
(define (top-interp [s : Sexp]) : String
  (type-check (parse s) base-tenv) 
  (define result (interp (parse s) top-env top-store))
  (serialize (Result-value result) (Result-store result)))


;; ---------- Test Cases ---------------

;; Primops 
(check-equal? (num+ (list 3 7) top-store) (Result 10 top-store))
(check-exn #rx"was not a number"
           (lambda () (num+ (list #t 3) top-store)))
(check-exn #rx"was not a number"
           (lambda () (num+ (list 3 #t) top-store)))

(check-equal? (num- (list 10 7) top-store) (Result 3 top-store))
(check-exn #rx"was not a number"
           (lambda () (num- (list #t 3) top-store)))
(check-exn #rx"was not a number"
           (lambda () (num- (list 3 #t) top-store)))

(check-equal? (num* (list 3 7) top-store) (Result 21 top-store))
(check-exn #rx"was not a number"
           (lambda () (num* (list #t 3) top-store)))
(check-exn #rx"was not a number"
           (lambda () (num* (list 3 #t) top-store)))

(check-equal? (num/ (list 10 2) top-store) (Result 5 top-store))
(check-exn #rx"was not a number"
           (lambda () (num/ (list #t 3) top-store)))
(check-exn #rx"was not a number"
           (lambda () (num/ (list 3 #t) top-store)))
(check-exn #rx"second arg cannot be zero"
           (lambda () (num/ (list 3 0) top-store)))

(check-equal? (lteq (list 10 2) top-store) (Result #f top-store))
(check-equal? (lteq (list 10 10) top-store) (Result #t top-store))
(check-equal? (lteq (list 2 10) top-store) (Result #t top-store))
(check-exn #rx"was not a number"
           (lambda () (lteq (list #t 3) top-store)))
(check-exn #rx"was not a number"
           (lambda () (lteq (list 3 #t) top-store)))

(check-equal? (num-eq? (list 10 2) top-store) (Result #f top-store))
(check-equal? (num-eq? (list 10 10) top-store) (Result #t top-store))
(check-equal? (num-eq? (list 2 10) top-store) (Result #f top-store))
(check-exn #rx"was not a number"
           (lambda () (num-eq? (list #t 3) top-store)))
(check-exn #rx"was not a number"
           (lambda () (num-eq? (list 3 #t) top-store)))

(check-equal? (str-eq? (list "hello" "hello") top-store) (Result #t top-store))
(check-equal? (str-eq? (list "cat" "dog") top-store) (Result #f top-store))
(check-equal? (str-eq? (list "a" "a") top-store) (Result #t top-store))
(check-exn #rx"was not a str"
           (lambda () (str-eq? (list #t "bill") top-store)))
(check-exn #rx"was not a str"
           (lambda () (str-eq? (list "bill" #t) top-store)))

(check-equal? (oazo-substring (list "hello" 1 2) top-store) (Result "e" top-store)) 
(check-exn #rx"OAZO"
           (lambda () (oazo-substring (list #t 1 2) top-store)))
(check-exn #rx"OAZO"
           (lambda () (oazo-substring (list "hello" "bill" "josh") top-store)))

;; testing arrays
(define arr-result1 (arr (list 3 4) top-store))
(define arr-result2 (arr (list 4 5) (Result-store arr-result1)))

(check-equal? (arr-eq? (list (Result-value arr-result1) (Result-value arr-result1)) (Result-store arr-result1))
              (Result #t (Result-store arr-result1)))
(check-equal? (arr-eq? (list (Result-value arr-result1) (Result-value arr-result2)) (Result-store arr-result2))
              (Result #f (Result-store arr-result2)))
(check-exn #rx"was not an array"
           (lambda () (arr-eq? (list (Result-value arr-result1) 3) top-store)))
(check-exn #rx"was not an array"
           (lambda () (arr-eq? (list 3 (Result-value arr-result1)) top-store)))

;; arr
(check-exn #rx"invalid arr syntax"
           (lambda () (arr (list 3 #t) top-store)))

;; aref
(check-equal? (aref (list (Result-value arr-result1) 2) (Result-store arr-result1))
              (Result 4 (Result-store arr-result1)))
(check-exn #rx"invalid aref syntax"
           (lambda () (aref (list (Result-value arr-result1) #t) (Result-store arr-result1))))
(check-exn #rx"invalid aref syntax"
           (lambda () (aref (list #t #t) (Result-store arr-result1))))

;; aset
(check-equal? (aset (list (Result-value arr-result1) 0 1) (Result-store arr-result1))
              (Result (NullV) (cons (Cell 15 1) (Result-store arr-result1))))
(check-exn #rx"invalid aset syntax"
           (lambda () (aset (list #t #t #t) (Result-store arr-result1))))

;; alen
(check-equal? (alen (list (Result-value arr-result1)) (Result-store arr-result1))
              (Result 3 (Result-store arr-result1)))
(check-exn #rx"not an array"
           (lambda () (alen (list #t) (Result-store arr-result1))))

;; serialize
(check-equal? (serialize 3 top-store) "3")
(check-equal? (serialize #t top-store) "true")
(check-equal? (serialize #f top-store) "false")
(check-equal? (serialize "hello" top-store) "\"hello\"")
(check-equal? (serialize (ClosV '() (NumC 0) '()) top-store) "#<procedure>")
(check-equal? (serialize (PrimopV num+) top-store) "#<primop>")
(check-equal? (serialize (NullV) top-store) "null")
(check-equal? (serialize (ArrayV 1 2) top-store) "#<array>")

;; check-id
(check-equal? (check-id 'if) #t)
(check-equal? (check-id 'then) #t)
(check-equal? (check-id 'else) #t)
(check-equal? (check-id 'let) #t)
(check-equal? (check-id 'bob) #f)

;; store-size? and allocate
(check-equal? (store-size? top-store) 15)
(check-equal? (allocate top-store (list 15 16 17 18) 1)
              (cons 15 (append (list (Cell 18 1) (Cell 17 1) (Cell 16 1) (Cell 15 1)) top-store )))

;; parse
(check-equal? (parse '4) (NumC 4))
(check-equal? (parse '{anon {[num x]  [num y]} : {+ x y}})
              (LamC (list 'x 'y) (AppC (IdC '+) (list (IdC 'x) (IdC 'y))) (list (NumT) (NumT))))
(check-equal? (parse '{{anon {[num x]} : {+ x 1}} 4})
              (AppC (LamC (list 'x) (AppC (IdC '+) (list (IdC 'x) (NumC 1))) (list (NumT))) (list (NumC 4))))
(check-equal? (parse '{if {equal? 1 1} then {+ 3 4} else {- 10 4}})
              (IfC
               (AppC (IdC 'equal?) (list (NumC 1) (NumC 1)))
               (AppC (IdC '+) (list (NumC 3) (NumC 4)))
               (AppC (IdC '-) (list (NumC 10) (NumC 4)))))
(check-equal? (parse '{let [[z : num] <- {+ 9 14}] [[y : num] <- 98] {+ z y}})
              (AppC (LamC (list 'z 'y) (AppC (IdC '+) (list (IdC 'z) (IdC 'y))) (list (NumT) (NumT)))
                    (list (AppC (IdC '+) (list (NumC 9) (NumC 14)))
                          (NumC 98))))
(check-equal? (parse '"hello") (StringC "hello"))
(check-equal? (parse '{seq {+ 1 2} {+ 2 3} {- 3 4}})
              (SeqC (list (AppC (IdC '+) (list (NumC 1) (NumC 2)))
                          (AppC (IdC '+) (list (NumC 2) (NumC 3))) (AppC (IdC '-) (list (NumC 3) (NumC 4))))))
(check-equal? (parse '{f := 3}) (MutC (IdC 'f) (NumC 3)))


(check-equal? (top-interp '{let
  {[z : num] <- {+ 9 14}}
  {[y : num] <- 98}
  {+ z y}}) "121")


(check-exn #rx"OAZO - cannot have duplicate ids"
           (lambda () (parse '{let [[x : num] <- 10] [[x : num] <- 12] {+ x x}})))
(check-exn #rx"OAZO - invalid id name"
           (lambda () (parse '{let [if <- 10] [x <- 12] {+ x then}})))
(check-exn #rx"OAZO - invalid id name"
           (lambda () (parse '{let [then <- 10] [x <- 12] {+ x then}})))
(check-exn #rx"OAZO - invalid id name"
           (lambda () (parse '{let [else <- 10] [x <- 12] {+ x then}})))
(check-exn #rx"OAZO - invalid id name"
           (lambda () (parse '{let [: <- 10] [x <- 12] {+ x then}})))
(check-exn #rx"OAZO - invalid id name"
           (lambda () (parse '{let [anon <- 10] [x <- 12] {+ x then}})))
(check-exn #rx"OAZO - invalid id name"
           (lambda () (parse '{let [<- <- 10] [x <- 12] {+ x then}})))
(check-exn #rx"OAZO - invalid id name"
           (lambda () (parse '{then})))
(check-exn #rx"OAZO - invalid id name"
           (lambda () (parse '{let [seq <- 10] {+ 1 seq}})))
(check-exn #rx"OAZO - cannot have duplicate ids"
           (lambda () (parse '{{anon {[num z] [num z]} : {+ z z}} {+ 9 14} 98})))
(check-exn #rx"OAZO - invalid id name"
           (lambda () (parse '{{anon {[num z] [num else]} : {+ else z}} {+ 9 14} 98})))
(check-exn #rx"OAZO - incomplete if statement"
           (lambda () (parse '{if {equal? 1 1} else {* 3 1}})))
(check-exn #rx"OAZO - parse error in: "
           (lambda () (parse '{})))


;; parse-type
(check-equal? (type-check (NumC 3) base-tenv) (NumT))
(check-equal? (type-check (AppC (IdC '+) (list (NumC 3) (NumC 4))) base-tenv) (NumT))
(check-equal? (type-check (AppC (IdC '*) (list (AppC (IdC '+) (list (NumC 3) (NumC 4))) (NumC 9))) base-tenv) (NumT))
(check-equal? (type-check (parse '{{anon {[num x] [num y]} : {+ x y}} 3 4}) base-tenv) (NumT))
(check-equal? (type-check (parse '{if {<= 1 0} then {+ 2 1} else {- 9 8}}) base-tenv) (NumT))
(check-exn #rx"OAZO"
           (lambda () (type-check (parse '{if {<= 0 1} then {+ 2 1} else "hello"}) base-tenv)))
(check-exn #rx"OAZO"
           (lambda () (type-check (parse '{if {+ 3 1} then {+ 2 1} else {+ 1 2}}) base-tenv)))
(check-exn #rx"OAZO"
           (lambda () (type-check (parse '{+ 3 "hello"}) base-tenv)))

;; interp
(check-equal? (interp (parse '4) top-env top-store) (Result 4 top-store))
(check-equal? (interp (parse '{+ 3 4}) top-env top-store) (Result 7 top-store))
(check-equal? (interp (parse '{+ {* 3 4} {+ 2 7}})  top-env top-store) (Result 21 top-store))
(check-equal? (interp (parse '{- {* 3 4} {/ 10 2}}) top-env top-store) (Result 7 top-store))
(check-equal? (interp (parse '{{anon {[num x] [num y]} : {+ x y}} 5 7}) top-env top-store)
              (Result 12 (cons (Cell 16 7) (cons (Cell 15 5) top-store))))
(check-equal? (interp (parse '"hello") top-env top-store) (Result "hello" top-store))
(check-equal? (interp (parse '{aset {arr 3 4} 0 1}) top-env top-store)
              (Result (NullV) (cons (Cell 15 1) (Result-store arr-result1))))
(check-equal? (interp (parse '{let [[x : num] <- 3] {+ {seq {x := 8} {+ x 3}} 9}}) top-env top-store)
              (Result 20 (cons (Cell 15 8) (cons (Cell 15 3) top-store)))) 
(check-exn #rx"OAZO - id was incorrect format"
           (lambda () (interp (MutC (NumC 3) (NumC 3)) top-env top-store)))
;; lookup
(check-equal? (lookup '+ top-env) 2)
(check-exn #rx"OAZO - 'bob is not defined"
           (lambda () (lookup 'bob top-env)))

;; lookup type
(check-exn #rx"OAZO - 'bob is not defined"
           (lambda () (lookup-type 'bob base-tenv)))

;; fetch
(check-exn #rx"OAZO - 20 is not defined"
           (lambda () (fetch 20 top-store)))


(check-equal? (top-interp '{{anon {} : {+ 3 4}}}) "7")
(check-equal? (top-interp '{let [[x : num] <- 4] {+ {let [[x : num] <- 12] x} x}}) "16")
(check-equal? (top-interp '{anon {[num x]} : {+ x 1}}) "#<procedure>")
(check-exn #rx"OAZO - 'f is not defined"
           (lambda () (top-interp
                       '{let [[f : (num -> num)] <- {anon {[num x]} : {+ x 1}}] [[y : num] <- {f 4}] {* {f 3} y}})))
(check-equal? (top-interp '{arr-eq? {arr 4 3} {arr 7 4}}) "false")
(check-equal? (top-interp '{* 3 {+ 3 4}}) "21")
(check-exn #rx"OAZO - 'f is not defined"
           (lambda () (top-interp
                       '{let [[f : (num -> num)] <- {anon {[num x]} : {+ x 1}}] [[y : num] <- {f 4}] {* {f 3} y}})))
(check-equal? (top-interp '{let [[x : num] <- 4] {+ {let [[x : num] <- 12] x} x}}) "16")
(check-equal? (top-interp '{anon {[num x]} : {+ x 1}}) "#<procedure>")
(check-equal? (top-interp '{{anon {[num x] [num y]} : {+ x y}} 5 7}) "12")
(check-equal? (top-interp '{if {num-eq? 1 1} then {+ 3 4} else {- 10 4}}) "7")
(check-equal? (top-interp '{if {<= 4 1} then {+ 3 4} else {- 10 4}}) "6")
(check-equal? (top-interp '{let [[z : num] <- {+ 9 14}] [[y : num] <- 98] {+ z y}}) "121")
(check-exn #rx"OAZO"
           (lambda () (top-interp '{if 4 then {+ 3 4} else {- 10 4}})))
(check-exn #rx"OAZO"
           (lambda () (interp (parse '{if 4 then {+ 3 4} else {- 10 4}}) top-env top-store)))
(check-exn #rx"OAZO - wrong number of arguments provided"
           (lambda () (interp (parse '{{anon {[num x] [num y]} : {+ x y}} 5}) top-env top-store)))
(check-exn #rx"OAZO - invalid application"
           (lambda () (interp (AppC (NumC 1) (list (NumC 2) (NumC 3))) top-env top-store)))
(check-equal? (type-check (parse '{anon {[num index] [numarray myarray]} : {aset myarray index 15}}) base-tenv)
              (FunT (list (NumT) (ArrayT)) (VoidT)))
(check-equal? (type-check (parse '{anon {[void x] [bool y] [str t]} : {if y then {+ 1 2} else {- 15 3}}}) base-tenv)
              (FunT (list (VoidT) (BoolT) (StrT)) (NumT)))


