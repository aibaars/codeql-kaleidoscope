private import codeql.Locations
private import TreeSitter

cached
private newtype TAstNode =
  TBinaryOpExpression(Kaleidoscope::BinaryOpExpression e) or
  TBinaryPrototype(Kaleidoscope::BinaryPrototype e) or
  TConditionalExpression(Kaleidoscope::ConditionalExpression e) or
  TExternalDeclaration(Kaleidoscope::ExternalDeclaration e) or
  TForExpression(Kaleidoscope::ForExpression e) or
  TFunctionCallExpression(Kaleidoscope::FunctionCallExpression e) or
  TFunctionDefinition(Kaleidoscope::FunctionDefinition e) or
  TFunctionPrototype(Kaleidoscope::FunctionPrototype e) or
  TIdentifier(Kaleidoscope::Identifier e) or
  TInitializer(Kaleidoscope::Initializer e) or
  TNumberLiteral(Kaleidoscope::Number e) or
  TDefaultStep(Kaleidoscope::ReservedWord e) {
    e.getValue() = "in" and
    e.getParent() = any(Kaleidoscope::ForExpression f | not exists(f.getUpdate()))
  } or
  TParenExpression(Kaleidoscope::ParenExpression e) or
  TProgram(Kaleidoscope::Program e) or
  TUnaryOpExpression(Kaleidoscope::UnaryOpExpression e) or
  TUnaryPrototype(Kaleidoscope::UnaryPrototype e) or
  TVarInExpression(Kaleidoscope::VarInExpression e) or
  TVariableExpression(Kaleidoscope::VariableExpression e)

Kaleidoscope::AstNode toTreeSitter(TAstNode node) {
  TBinaryOpExpression(result) = node
  or
  TBinaryPrototype(result) = node
  or
  TConditionalExpression(result) = node
  or
  TDefaultStep(result) = node
  or
  TExternalDeclaration(result) = node
  or
  TForExpression(result) = node
  or
  TFunctionCallExpression(result) = node
  or
  TFunctionDefinition(result) = node
  or
  TFunctionPrototype(result) = node
  or
  TIdentifier(result) = node
  or
  TInitializer(result) = node
  or
  TNumberLiteral(result) = node
  or
  TParenExpression(result) = node
  or
  TProgram(result) = node
  or
  TUnaryOpExpression(result) = node
  or
  TUnaryPrototype(result) = node
  or
  TVarInExpression(result) = node
  or
  TVariableExpression(result) = node
}

abstract class AstNodeImpl extends TAstNode {
  abstract AstNodeImpl getAChild(string name);

  abstract string toString();

  abstract string getAPrimaryQlClass();

  abstract Location getLocation();
}

private class TExpression =
  TBinaryOpExpression or TConditionalExpression or TForExpression or TFunctionCallExpression or
      TNumber or TParenExpression or TUnaryOpExpression or TVarInExpression or TVariableExpression;

abstract class ExpressionImpl extends StatementImpl, TExpression { }

class BinaryOpExpressionImpl extends ExpressionImpl, TBinaryOpExpression {
  private Kaleidoscope::BinaryOpExpression node;

  BinaryOpExpressionImpl() { this = TBinaryOpExpression(node) }

  override AstNodeImpl getAChild(string name) {
    name = "getLhs" and result = this.getLhs()
    or
    name = "getOperator" and result = this.getOperator()
    or
    name = "getRhs" and result = this.getRhs()
  }

  override string toString() { result = "..." + this.getOperator().getName() + "..." }

  override string getAPrimaryQlClass() { result = "BinaryOpExpression" }

  override Location getLocation() { result = node.getLocation() }

  ExpressionImpl getLhs() { toTreeSitter(result) = node.getLhs() }

  ExpressionImpl getRhs() { toTreeSitter(result) = node.getRhs() }

  IdentifierImpl getOperator() { toTreeSitter(result) = node.getOperator() }
}

class ConditionalExpressionImpl extends ExpressionImpl, TConditionalExpression {
  private Kaleidoscope::ConditionalExpression node;

  ConditionalExpressionImpl() { this = TConditionalExpression(node) }

  override AstNodeImpl getAChild(string name) {
    name = "getCondition" and result = this.getCondition()
    or
    name = "getThen" and result = this.getThen()
    or
    name = "getElse" and result = this.getElse()
  }

  override string toString() { result = "if ... then ... else ..." }

  override string getAPrimaryQlClass() { result = "ConditionalExpression" }

  override Location getLocation() { result = node.getLocation() }

  ExpressionImpl getCondition() { toTreeSitter(result) = node.getCondition() }

  ExpressionImpl getThen() { toTreeSitter(result) = node.getThen() }

  ExpressionImpl getElse() { toTreeSitter(result) = node.getElse() }
}

class ForExpressionImpl extends ExpressionImpl, TForExpression {
  private Kaleidoscope::ForExpression node;

  ForExpressionImpl() { this = TForExpression(node) }

  override AstNodeImpl getAChild(string name) {
    name = "getInitializer" and result = this.getInitializer()
    or
    name = "getCondition" and result = this.getCondition()
    or
    name = "getStep" and result = this.getStep()
    or
    name = "getBody" and result = this.getBody()
  }

  override string toString() { result = "for ... in ..." }

  override string getAPrimaryQlClass() { result = "ForExpression" }

  override Location getLocation() { result = node.getLocation() }

  InitializerImpl getInitializer() { toTreeSitter(result) = node.getInitializer() }

  ExpressionImpl getCondition() { toTreeSitter(result) = node.getCondition() }

  ExpressionImpl getStep() {
    toTreeSitter(result) = node.getUpdate()
    or
    not exists(node.getUpdate()) and
    result = TDefaultStep(any(Kaleidoscope::ReservedWord i | i.getParent() = node))
  }

  ExpressionImpl getBody() { toTreeSitter(result) = node.getBody() }
}

class FunctionCallExpressionImpl extends ExpressionImpl, TFunctionCallExpression {
  private Kaleidoscope::FunctionCallExpression node;

  FunctionCallExpressionImpl() { this = TFunctionCallExpression(node) }

  override AstNodeImpl getAChild(string name) {
    name = "getCallee" and result = this.getCallee()
    or
    name = "getArgument" and result = this.getArgument(_)
  }

  override string toString() { result = this.getCallee().getName() + "(...)" }

  override string getAPrimaryQlClass() { result = "FunctionCallExpression" }

  override Location getLocation() { result = node.getLocation() }

  IdentifierImpl getCallee() { toTreeSitter(result) = node.getCallee() }

  ExpressionImpl getArgument(int index) { toTreeSitter(result) = node.getArgument(index) }
}

private class TNumber = TDefaultStep or TNumberLiteral;

abstract class NumberImpl extends ExpressionImpl, TNumber {
  override string getAPrimaryQlClass() { result = "NumberLiteral" }

  override AstNodeImpl getAChild(string name) { none() }

  abstract string getValue();
}

class NumberLiteralImpl extends NumberImpl, TNumberLiteral {
  private Kaleidoscope::Number node;

  NumberLiteralImpl() { this = TNumberLiteral(node) }

  override string toString() { result = node.getValue() }

  override Location getLocation() { result = node.getLocation() }

  override string getValue() { result = node.getValue() }
}

class DefaultStepImpl extends NumberImpl, TDefaultStep {
  private Kaleidoscope::ReservedWord node;

  DefaultStepImpl() { this = TDefaultStep(node) }

  override string toString() { result = "1.0" }

  override Location getLocation() { result = node.getLocation() }

  override string getValue() { result = "1.0" }
}

class ParenExpressionImpl extends ExpressionImpl, TParenExpression {
  private Kaleidoscope::ParenExpression node;

  ParenExpressionImpl() { this = TParenExpression(node) }

  override AstNodeImpl getAChild(string name) {
    name = "getExpression" and result = this.getExpression()
  }

  override string toString() { result = "(...)" }

  override string getAPrimaryQlClass() { result = "ParenExpression" }

  override Location getLocation() { result = node.getLocation() }

  ExpressionImpl getExpression() { toTreeSitter(result) = node.getExpr() }
}

class UnaryOpExpressionImpl extends ExpressionImpl, TUnaryOpExpression {
  private Kaleidoscope::UnaryOpExpression node;

  UnaryOpExpressionImpl() { this = TUnaryOpExpression(node) }

  override AstNodeImpl getAChild(string name) {
    name = "getOperator" and result = this.getOperator()
    or
    name = "getOperand" and result = this.getOperand()
  }

  override string toString() { result = this.getOperator().getName() + "..." }

  override string getAPrimaryQlClass() { result = "UnaryOpExpression" }

  override Location getLocation() { result = node.getLocation() }

  ExpressionImpl getOperand() { toTreeSitter(result) = node.getOperand() }

  IdentifierImpl getOperator() { toTreeSitter(result) = node.getOperator() }
}

class VarInExpressionImpl extends ExpressionImpl, TVarInExpression {
  private Kaleidoscope::VarInExpression node;

  VarInExpressionImpl() { this = TVarInExpression(node) }

  override AstNodeImpl getAChild(string name) {
    name = "getInitializer" and result = this.getInitializer(_)
    or
    name = "getBody" and result = this.getBody()
  }

  override string toString() { result = "var ... in ..." }

  override string getAPrimaryQlClass() { result = "VarInExpression" }

  override Location getLocation() { result = node.getLocation() }

  InitializerImpl getInitializer(int index) { toTreeSitter(result) = node.getInitializer(index) }

  ExpressionImpl getBody() { toTreeSitter(result) = node.getExpr() }
}

class VariableExpressionImpl extends ExpressionImpl, TVariableExpression {
  private Kaleidoscope::VariableExpression node;

  VariableExpressionImpl() { this = TVariableExpression(node) }

  override AstNodeImpl getAChild(string name) {
    name = "getVariable" and result = this.getVariable()
  }

  override string toString() { result = this.getVariable().getName() }

  override string getAPrimaryQlClass() { result = "VariableExpression" }

  override Location getLocation() { result = node.getLocation() }

  IdentifierImpl getVariable() { toTreeSitter(result) = node.getName() }
}

class IdentifierImpl extends AstNodeImpl, TIdentifier {
  private Kaleidoscope::Identifier node;

  IdentifierImpl() { this = TIdentifier(node) }

  override string toString() { result = node.getValue() }

  override AstNodeImpl getAChild(string name) { none() }

  override string getAPrimaryQlClass() { result = "Identifier" }

  override Location getLocation() { result = node.getLocation() }

  string getName() { result = node.getValue() }
}

class InitializerImpl extends AstNodeImpl, TInitializer {
  private Kaleidoscope::Initializer node;

  InitializerImpl() { this = TInitializer(node) }

  override AstNodeImpl getAChild(string name) {
    name = "getVariable" and result = this.getVariable()
    or
    name = "getExpression" and result = this.getExpression()
  }

  override string toString() { result = "... = ..." }

  override string getAPrimaryQlClass() { result = "Initializer" }

  override Location getLocation() { result = node.getLocation() }

  IdentifierImpl getVariable() { toTreeSitter(result) = node.getVariable() }

  ExpressionImpl getExpression() { toTreeSitter(result) = node.getExpr() }
}

private class TPrototype = TBinaryPrototype or TFunctionPrototype or TUnaryPrototype;

abstract class PrototypeImpl extends AstNodeImpl, TPrototype {
  override AstNodeImpl getAChild(string name) {
    name = "getIdentifier" and result = this.getIdentifier()
    or
    name = "getArgument" and result = this.getArgument(_)
  }

  IdentifierImpl getIdentifier() { none() }

  IdentifierImpl getArgument(int index) { none() }
}

class BinaryPrototypeImpl extends PrototypeImpl, TBinaryPrototype {
  private Kaleidoscope::BinaryPrototype node;

  BinaryPrototypeImpl() { this = TBinaryPrototype(node) }

  override string toString() { result = "binary " + this.getIdentifier().getName() + "(...)" }

  override string getAPrimaryQlClass() { result = "BinaryPrototype" }

  override Location getLocation() { result = node.getLocation() }

  override AstNodeImpl getAChild(string name) {
    result = super.getAChild(name)
    or
    name = "getPrecedence" and result = this.getPrecedence()
  }

  NumberLiteralImpl getPrecedence() { toTreeSitter(result) = node.getPrecedence() }

  override IdentifierImpl getIdentifier() { toTreeSitter(result) = node.getName() }

  override IdentifierImpl getArgument(int index) { toTreeSitter(result) = node.getArgument(index) }
}

class UnaryPrototypeImpl extends PrototypeImpl, TUnaryPrototype {
  private Kaleidoscope::UnaryPrototype node;

  UnaryPrototypeImpl() { this = TUnaryPrototype(node) }

  override string toString() { result = "unary " + this.getIdentifier().getName() + "(...)" }

  override string getAPrimaryQlClass() { result = "UnaryPrototype" }

  override Location getLocation() { result = node.getLocation() }

  override IdentifierImpl getIdentifier() { toTreeSitter(result) = node.getName() }

  IdentifierImpl getArgument() { toTreeSitter(result) = node.getArgument() }

  override IdentifierImpl getArgument(int index) {
    index = 0 and toTreeSitter(result) = node.getArgument()
  }
}

class FunctionPrototypeImpl extends PrototypeImpl, TFunctionPrototype {
  private Kaleidoscope::FunctionPrototype node;

  FunctionPrototypeImpl() { this = TFunctionPrototype(node) }

  override string toString() { result = this.getIdentifier().getName() + "(...)" }

  override string getAPrimaryQlClass() { result = "FunctionPrototype" }

  override Location getLocation() { result = node.getLocation() }

  override IdentifierImpl getIdentifier() { toTreeSitter(result) = node.getName() }

  override IdentifierImpl getArgument(int index) { toTreeSitter(result) = node.getArgument(index) }
}

private class TDeclaration = TFunctionDefinition or TExternalDeclaration;

abstract class DeclarationImpl extends StatementImpl, TDeclaration {
  override AstNodeImpl getAChild(string name) {
    name = "getPrototype" and result = this.getPrototype()
  }

  PrototypeImpl getPrototype() { none() }
}

class FunctionDefinitionImpl extends DeclarationImpl, TFunctionDefinition {
  private Kaleidoscope::FunctionDefinition node;

  FunctionDefinitionImpl() { this = TFunctionDefinition(node) }

  override AstNodeImpl getAChild(string name) {
    result = super.getAChild(name)
    or
    name = "getBody" and result = this.getBody()
  }

  override string toString() { result = "def ... = ..." }

  override string getAPrimaryQlClass() { result = "FunctionDefinition" }

  override Location getLocation() { result = node.getLocation() }

  override PrototypeImpl getPrototype() { toTreeSitter(result) = node.getPrototype() }

  ExpressionImpl getBody() { toTreeSitter(result) = node.getBody() }
}

class ExternalDeclarationImpl extends DeclarationImpl, TExternalDeclaration {
  private Kaleidoscope::ExternalDeclaration node;

  ExternalDeclarationImpl() { this = TExternalDeclaration(node) }

  override string toString() { result = "extern ..." }

  override string getAPrimaryQlClass() { result = "ExternalDeclaration" }

  override Location getLocation() { result = node.getLocation() }

  override PrototypeImpl getPrototype() { toTreeSitter(result) = node.getPrototype() }
}

private class TStatement = TDeclaration or TExpression;

abstract class StatementImpl extends AstNodeImpl, TStatement { }

class ProgramImpl extends AstNodeImpl, TProgram {
  private Kaleidoscope::Program node;

  ProgramImpl() { this = TProgram(node) }

  override AstNodeImpl getAChild(string name) {
    name = "getStatement" and result = this.getStatement(_)
  }

  override string toString() { result = "..." }

  override string getAPrimaryQlClass() { result = "Program" }

  override Location getLocation() { result = node.getLocation() }

  StatementImpl getStatement(int index) { toTreeSitter(result) = node.getStatement(index) }
}
