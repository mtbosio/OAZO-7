# OAZO-7
OAZO-7 is a language I created for my CSC 430 Programming Languages class. It is a custom-designed language developed in typed Racket with a defined syntax, type system, and operational semantics.

Here is the Backus-Naur Form (BNF):

---------------- OAZO7 ----------------

 Expr	 	=	 	Num
 	 	|	 	id
 	 	|	 	String
 	 	|	 	{id := Expr}
 	 	|	 	{if Expr then Expr else Expr}
	 	|	 	{let [[id : ty] <- Expr] ... Expr}
	 	|	 	{anon {[ty id] ...} : Expr}
 	 	|	 	{seq Expr ...}
 	 	|	 	{Expr Expr ...}
 ty	 	=	 	num
 	 	|	 	bool
 	 	|	 	str
 	 	|	 	void
 	 	|	 	{ty ... -> ty}
 	 	|	 	numarray
 operator	=	 	+
 	 	|	 	-
 	 	|	 	*
 	 	|	 	/
 	 	|	 	num-eq?
 	 	|	 	str-eq?
 	 	|	 	<=
 	 	|	 	substring
 	 	|	 	arr
 	 	|	 	aref
 	 	|	 	aset
 	 	|	 	alen

where an id is not let, :=, if, then, else, :, <-, seq

Key Features
1. Expressions:
  Numeric and String Values: Supports numeric literals and string literals.
  Identifiers: Allows the use of identifiers for variable names.
  Assignment: Uses {id := Expr} for variable assignments.
  Conditionals: Implements conditional expressions with {if Expr then Expr else Expr}.
  Let Bindings: Supports local bindings with {let [[id : ty] <- Expr] ... Expr}.
  Anonymous Functions: Creates anonymous functions with {anon {[ty id] ...} : Expr}.
  Sequences: Evaluates multiple expressions in sequence with {seq Expr ...}.
  Function Application: Applies functions to arguments with {Expr Expr ...}..
2. Types:
  Primitive Types: Includes num (numeric), bool (boolean), str (string), and void (no return value).
  Function Types: Defines functions with {ty ... -> ty} for specifying argument and return types.
  Array Types: Supports arrays with the numarray type.
3. Operators:
  Arithmetic: Operators like +, -, *, /.
  Comparison: Includes num-eq?, str-eq?, <= for comparisons.
  String Operations: Functions like substring for string manipulation.
  Array Operations: Operations for array creation (arr), access (aref), modification (aset), and length (alen).
4. Values:
  Closures: Represents functions with their environments.
  Primitive Operations: Built-in functions for basic operations.
  Arrays: Represents arrays and their manipulation.
  Null Values: Handles null values in expressions.
5. Environment and Store:
  Environment (Env): Manages bindings between identifiers and memory locations.
  Store: Handles memory allocation and value storage.
6. Functions:
  Primitive Operations: Includes functions for arithmetic, string operations, and array manipulations.
  Memory Management: Functions for allocating memory and managing arrays.
7. Error Handling:
  Includes mechanisms to handle errors related to type mismatches and out-of-bounds operations.

Here of some examples of using the language:
<img width="850" alt="Screenshot 2024-08-18 at 8 19 00 PM" src="https://github.com/user-attachments/assets/75fbdb1f-1a93-4274-9f92-78c79f4bf9df">

As you can see, when evaluating these expressions the computed values are as expected (in order):
<img width="432" alt="Screenshot 2024-08-17 at 11 56 47 AM" src="https://github.com/user-attachments/assets/14d1ef18-afd2-4992-b904-27c51f295efd">

And here is a small, simple interactive text game I made using the language:
<img width="991" alt="Screenshot 2024-08-17 at 11 44 21 AM" src="https://github.com/user-attachments/assets/8a118dbb-de5c-429b-a920-35d9e0d5172c">

And the result:

<img width="436" alt="Screenshot 2024-08-17 at 11 43 59 AM" src="https://github.com/user-attachments/assets/0eb87a77-6d5f-48b5-a95b-53feb95e9f42">


