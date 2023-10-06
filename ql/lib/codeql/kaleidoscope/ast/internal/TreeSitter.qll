/**
 * CodeQL library for Kaleidoscope
 * Automatically generated from the tree-sitter grammar; do not edit
 */

import codeql.Locations as L

module Kaleidoscope {
  /** The base class for all AST nodes */
  class AstNode extends @kaleidoscope_ast_node {
    /** Gets a string representation of this element. */
    string toString() { result = this.getAPrimaryQlClass() }

    /** Gets the location of this element. */
    final L::Location getLocation() { kaleidoscope_ast_node_info(this, _, _, result) }

    /** Gets the parent of this element. */
    final AstNode getParent() { kaleidoscope_ast_node_info(this, result, _, _) }

    /** Gets the index of this node among the children of its parent. */
    final int getParentIndex() { kaleidoscope_ast_node_info(this, _, result, _) }

    /** Gets a field or child node of this node. */
    AstNode getAFieldOrChild() { none() }

    /** Gets the name of the primary QL class for this element. */
    string getAPrimaryQlClass() { result = "???" }

    /** Gets a comma-separated list of the names of the primary CodeQL classes to which this element belongs. */
    string getPrimaryQlClasses() { result = concat(this.getAPrimaryQlClass(), ",") }
  }

  /** A token. */
  class Token extends @kaleidoscope_token, AstNode {
    /** Gets the value of this token. */
    final string getValue() { kaleidoscope_tokeninfo(this, _, result) }

    /** Gets a string representation of this element. */
    final override string toString() { result = this.getValue() }

    /** Gets the name of the primary QL class for this element. */
    override string getAPrimaryQlClass() { result = "Token" }
  }

  /** A reserved word. */
  class ReservedWord extends @kaleidoscope_reserved_word, Token {
    /** Gets the name of the primary QL class for this element. */
    final override string getAPrimaryQlClass() { result = "ReservedWord" }
  }

  class UnderscoreExpression extends @kaleidoscope_underscore_expression, AstNode { }

  class UnderscorePrimaryExpression extends @kaleidoscope_underscore_primary_expression, AstNode { }

  class UnderscorePrototype extends @kaleidoscope_underscore_prototype, AstNode { }

  class UnderscoreRepl extends @kaleidoscope_underscore_repl, AstNode { }

  /** A class representing `binaryOpExpression` nodes. */
  class BinaryOpExpression extends @kaleidoscope_binary_op_expression, AstNode {
    /** Gets the name of the primary QL class for this element. */
    final override string getAPrimaryQlClass() { result = "BinaryOpExpression" }

    /** Gets the node corresponding to the field `lhs`. */
    final UnderscoreExpression getLhs() {
      kaleidoscope_binary_op_expression_def(this, result, _, _)
    }

    /** Gets the node corresponding to the field `operator`. */
    final Identifier getOperator() { kaleidoscope_binary_op_expression_def(this, _, result, _) }

    /** Gets the node corresponding to the field `rhs`. */
    final UnderscoreExpression getRhs() {
      kaleidoscope_binary_op_expression_def(this, _, _, result)
    }

    /** Gets a field or child node of this node. */
    final override AstNode getAFieldOrChild() {
      kaleidoscope_binary_op_expression_def(this, result, _, _) or
      kaleidoscope_binary_op_expression_def(this, _, result, _) or
      kaleidoscope_binary_op_expression_def(this, _, _, result)
    }
  }

  /** A class representing `binaryPrototype` nodes. */
  class BinaryPrototype extends @kaleidoscope_binary_prototype, AstNode {
    /** Gets the name of the primary QL class for this element. */
    final override string getAPrimaryQlClass() { result = "BinaryPrototype" }

    /** Gets the node corresponding to the field `argument`. */
    final Identifier getArgument(int i) { kaleidoscope_binary_prototype_argument(this, i, result) }

    /** Gets the node corresponding to the field `name`. */
    final Identifier getName() { kaleidoscope_binary_prototype_def(this, result) }

    /** Gets the node corresponding to the field `precedence`. */
    final Number getPrecedence() { kaleidoscope_binary_prototype_precedence(this, result) }

    /** Gets a field or child node of this node. */
    final override AstNode getAFieldOrChild() {
      kaleidoscope_binary_prototype_argument(this, _, result) or
      kaleidoscope_binary_prototype_def(this, result) or
      kaleidoscope_binary_prototype_precedence(this, result)
    }
  }

  /** A class representing `conditionalExpression` nodes. */
  class ConditionalExpression extends @kaleidoscope_conditional_expression, AstNode {
    /** Gets the name of the primary QL class for this element. */
    final override string getAPrimaryQlClass() { result = "ConditionalExpression" }

    /** Gets the node corresponding to the field `condition`. */
    final UnderscoreExpression getCondition() {
      kaleidoscope_conditional_expression_def(this, result, _, _)
    }

    /** Gets the node corresponding to the field `else`. */
    final UnderscoreExpression getElse() {
      kaleidoscope_conditional_expression_def(this, _, result, _)
    }

    /** Gets the node corresponding to the field `then`. */
    final UnderscoreExpression getThen() {
      kaleidoscope_conditional_expression_def(this, _, _, result)
    }

    /** Gets a field or child node of this node. */
    final override AstNode getAFieldOrChild() {
      kaleidoscope_conditional_expression_def(this, result, _, _) or
      kaleidoscope_conditional_expression_def(this, _, result, _) or
      kaleidoscope_conditional_expression_def(this, _, _, result)
    }
  }

  /** A class representing `externalDeclaration` nodes. */
  class ExternalDeclaration extends @kaleidoscope_external_declaration, AstNode {
    /** Gets the name of the primary QL class for this element. */
    final override string getAPrimaryQlClass() { result = "ExternalDeclaration" }

    /** Gets the node corresponding to the field `prototype`. */
    final UnderscorePrototype getPrototype() { kaleidoscope_external_declaration_def(this, result) }

    /** Gets a field or child node of this node. */
    final override AstNode getAFieldOrChild() {
      kaleidoscope_external_declaration_def(this, result)
    }
  }

  /** A class representing `forExpression` nodes. */
  class ForExpression extends @kaleidoscope_for_expression, AstNode {
    /** Gets the name of the primary QL class for this element. */
    final override string getAPrimaryQlClass() { result = "ForExpression" }

    /** Gets the node corresponding to the field `body`. */
    final UnderscoreExpression getBody() { kaleidoscope_for_expression_def(this, result, _, _) }

    /** Gets the node corresponding to the field `condition`. */
    final UnderscoreExpression getCondition() {
      kaleidoscope_for_expression_def(this, _, result, _)
    }

    /** Gets the node corresponding to the field `initializer`. */
    final Initializer getInitializer() { kaleidoscope_for_expression_def(this, _, _, result) }

    /** Gets the node corresponding to the field `update`. */
    final UnderscoreExpression getUpdate() { kaleidoscope_for_expression_update(this, result) }

    /** Gets a field or child node of this node. */
    final override AstNode getAFieldOrChild() {
      kaleidoscope_for_expression_def(this, result, _, _) or
      kaleidoscope_for_expression_def(this, _, result, _) or
      kaleidoscope_for_expression_def(this, _, _, result) or
      kaleidoscope_for_expression_update(this, result)
    }
  }

  /** A class representing `functionCallExpression` nodes. */
  class FunctionCallExpression extends @kaleidoscope_function_call_expression, AstNode {
    /** Gets the name of the primary QL class for this element. */
    final override string getAPrimaryQlClass() { result = "FunctionCallExpression" }

    /** Gets the node corresponding to the field `argument`. */
    final UnderscoreExpression getArgument(int i) {
      kaleidoscope_function_call_expression_argument(this, i, result)
    }

    /** Gets the node corresponding to the field `callee`. */
    final Identifier getCallee() { kaleidoscope_function_call_expression_def(this, result) }

    /** Gets a field or child node of this node. */
    final override AstNode getAFieldOrChild() {
      kaleidoscope_function_call_expression_argument(this, _, result) or
      kaleidoscope_function_call_expression_def(this, result)
    }
  }

  /** A class representing `functionDefinition` nodes. */
  class FunctionDefinition extends @kaleidoscope_function_definition, AstNode {
    /** Gets the name of the primary QL class for this element. */
    final override string getAPrimaryQlClass() { result = "FunctionDefinition" }

    /** Gets the node corresponding to the field `body`. */
    final UnderscoreExpression getBody() { kaleidoscope_function_definition_def(this, result, _) }

    /** Gets the node corresponding to the field `prototype`. */
    final UnderscorePrototype getPrototype() {
      kaleidoscope_function_definition_def(this, _, result)
    }

    /** Gets a field or child node of this node. */
    final override AstNode getAFieldOrChild() {
      kaleidoscope_function_definition_def(this, result, _) or
      kaleidoscope_function_definition_def(this, _, result)
    }
  }

  /** A class representing `functionPrototype` nodes. */
  class FunctionPrototype extends @kaleidoscope_function_prototype, AstNode {
    /** Gets the name of the primary QL class for this element. */
    final override string getAPrimaryQlClass() { result = "FunctionPrototype" }

    /** Gets the node corresponding to the field `argument`. */
    final Identifier getArgument(int i) {
      kaleidoscope_function_prototype_argument(this, i, result)
    }

    /** Gets the node corresponding to the field `name`. */
    final Identifier getName() { kaleidoscope_function_prototype_def(this, result) }

    /** Gets a field or child node of this node. */
    final override AstNode getAFieldOrChild() {
      kaleidoscope_function_prototype_argument(this, _, result) or
      kaleidoscope_function_prototype_def(this, result)
    }
  }

  /** A class representing `identifier` tokens. */
  class Identifier extends @kaleidoscope_token_identifier, Token {
    /** Gets the name of the primary QL class for this element. */
    final override string getAPrimaryQlClass() { result = "Identifier" }
  }

  /** A class representing `initializer` nodes. */
  class Initializer extends @kaleidoscope_initializer, AstNode {
    /** Gets the name of the primary QL class for this element. */
    final override string getAPrimaryQlClass() { result = "Initializer" }

    /** Gets the node corresponding to the field `expr`. */
    final UnderscoreExpression getExpr() { kaleidoscope_initializer_expr(this, result) }

    /** Gets the node corresponding to the field `variable`. */
    final Identifier getVariable() { kaleidoscope_initializer_def(this, result) }

    /** Gets a field or child node of this node. */
    final override AstNode getAFieldOrChild() {
      kaleidoscope_initializer_expr(this, result) or kaleidoscope_initializer_def(this, result)
    }
  }

  /** A class representing `lineComment` tokens. */
  class LineComment extends @kaleidoscope_token_line_comment, Token {
    /** Gets the name of the primary QL class for this element. */
    final override string getAPrimaryQlClass() { result = "LineComment" }
  }

  /** A class representing `number` tokens. */
  class Number extends @kaleidoscope_token_number, Token {
    /** Gets the name of the primary QL class for this element. */
    final override string getAPrimaryQlClass() { result = "Number" }
  }

  /** A class representing `parenExpression` nodes. */
  class ParenExpression extends @kaleidoscope_paren_expression, AstNode {
    /** Gets the name of the primary QL class for this element. */
    final override string getAPrimaryQlClass() { result = "ParenExpression" }

    /** Gets the node corresponding to the field `expr`. */
    final UnderscoreExpression getExpr() { kaleidoscope_paren_expression_def(this, result) }

    /** Gets a field or child node of this node. */
    final override AstNode getAFieldOrChild() { kaleidoscope_paren_expression_def(this, result) }
  }

  /** A class representing `program` nodes. */
  class Program extends @kaleidoscope_program, AstNode {
    /** Gets the name of the primary QL class for this element. */
    final override string getAPrimaryQlClass() { result = "Program" }

    /** Gets the node corresponding to the field `statement`. */
    final UnderscoreRepl getStatement(int i) { kaleidoscope_program_statement(this, i, result) }

    /** Gets a field or child node of this node. */
    final override AstNode getAFieldOrChild() { kaleidoscope_program_statement(this, _, result) }
  }

  /** A class representing `unaryOpExpression` nodes. */
  class UnaryOpExpression extends @kaleidoscope_unary_op_expression, AstNode {
    /** Gets the name of the primary QL class for this element. */
    final override string getAPrimaryQlClass() { result = "UnaryOpExpression" }

    /** Gets the node corresponding to the field `operand`. */
    final UnderscoreExpression getOperand() {
      kaleidoscope_unary_op_expression_def(this, result, _)
    }

    /** Gets the node corresponding to the field `operator`. */
    final Identifier getOperator() { kaleidoscope_unary_op_expression_def(this, _, result) }

    /** Gets a field or child node of this node. */
    final override AstNode getAFieldOrChild() {
      kaleidoscope_unary_op_expression_def(this, result, _) or
      kaleidoscope_unary_op_expression_def(this, _, result)
    }
  }

  /** A class representing `unaryPrototype` nodes. */
  class UnaryPrototype extends @kaleidoscope_unary_prototype, AstNode {
    /** Gets the name of the primary QL class for this element. */
    final override string getAPrimaryQlClass() { result = "UnaryPrototype" }

    /** Gets the node corresponding to the field `argument`. */
    final Identifier getArgument() { kaleidoscope_unary_prototype_def(this, result, _) }

    /** Gets the node corresponding to the field `name`. */
    final Identifier getName() { kaleidoscope_unary_prototype_def(this, _, result) }

    /** Gets a field or child node of this node. */
    final override AstNode getAFieldOrChild() {
      kaleidoscope_unary_prototype_def(this, result, _) or
      kaleidoscope_unary_prototype_def(this, _, result)
    }
  }

  /** A class representing `varInExpression` nodes. */
  class VarInExpression extends @kaleidoscope_var_in_expression, AstNode {
    /** Gets the name of the primary QL class for this element. */
    final override string getAPrimaryQlClass() { result = "VarInExpression" }

    /** Gets the node corresponding to the field `expr`. */
    final UnderscoreExpression getExpr() { kaleidoscope_var_in_expression_def(this, result) }

    /** Gets the node corresponding to the field `initializer`. */
    final Initializer getInitializer(int i) {
      kaleidoscope_var_in_expression_initializer(this, i, result)
    }

    /** Gets a field or child node of this node. */
    final override AstNode getAFieldOrChild() {
      kaleidoscope_var_in_expression_def(this, result) or
      kaleidoscope_var_in_expression_initializer(this, _, result)
    }
  }

  /** A class representing `variableExpression` nodes. */
  class VariableExpression extends @kaleidoscope_variable_expression, AstNode {
    /** Gets the name of the primary QL class for this element. */
    final override string getAPrimaryQlClass() { result = "VariableExpression" }

    /** Gets the node corresponding to the field `name`. */
    final Identifier getName() { kaleidoscope_variable_expression_def(this, result) }

    /** Gets a field or child node of this node. */
    final override AstNode getAFieldOrChild() { kaleidoscope_variable_expression_def(this, result) }
  }
}
