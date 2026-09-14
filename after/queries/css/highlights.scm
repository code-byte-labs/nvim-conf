[
  "@media"
  "@charset"
  "@namespace"
  "@supports"
  "@keyframes"
  (at_keyword)
] @keyword.directive

"@import" @keyword.import

[
  (to)
  (from)
] @keyword

(comment) @comment @spell

(tag_name) @tag

(class_name) @type

(id_name) @id

[
  (property_name)
  (feature_name)
] @property

(function_name) @function

[
  "~"
  ">"
  "+"
  "-"
  "*"
  "/"
  "="
  "^="
  "|="
  "~="
  "$="
  "*="
] @operator

[
  "and"
  "or"
  "not"
  "only"
] @keyword.operator

(important) @keyword.modifier

[
  (nesting_selector)
  (universal_selector)
] @character.special

(attribute_selector
  (plain_value) @string)

(pseudo_element_selector
  "::"
  (tag_name) @pseudo)

(pseudo_class_selector
  (class_name) @pseudo)

(attribute_name) @tag.attribute

(namespace_name) @module

(keyframes_name) @variable

(plain_value) @value

((property_name) @variable
  (#lua-match? @variable "^[-][-]"))

((plain_value) @variable
  (#lua-match? @variable "^[-][-]"))

((plain_value) @property
  (#lua-match? @property "^%u"))

(string_value) @string

(color_value) @value

(unit) @unit

(integer_value) @number

(float_value) @number.float

[
  "#"
  ","
  "."
  ":"
  "::"
  ";"
] @punctuation.delimiter

(id_selector
  "#" @id)

(class_selector
  "." @type)

(pseudo_class_selector
  ":" @pseudo)

(pseudo_element_selector
  "::" @pseudo)

(child_selector
  ">" @punctuation.delimiter)

(color_value
  "#" @value)

[
  "{"
  ")"
  "("
  "}"
  "["
  "]"
] @punctuation.bracket
