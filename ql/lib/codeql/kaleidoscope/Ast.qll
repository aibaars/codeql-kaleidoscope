private import codeql.kaleidoscope.ast.internal.Ast
private import codeql.kaleidoscope.ast.internal.TreeSitter
private import codeql.Locations

final class AstNode instanceof AstNodeImpl {
  AstNode getAChild(string name) { result = super.getAChild(name) }

  AstNode getParent() { result.getAChild(_) = this }

  string toString() { result = super.toString() }

  string getAPrimaryQlClass() { result = super.getAPrimaryQlClass() }

  Location getLocation() { result = super.getLocation() }
}

final class Expression extends Statement instanceof ExpressionImpl { }

final class BinaryOpExpression extends Expression instanceof BinaryOpExpressionImpl {
  Expression getLhs() { result = super.getLhs() }

  Expression getRhs() { result = super.getRhs() }

  Identifier getOperator() { result = super.getOperator() }
}

final class ConditionalExpression extends Expression instanceof ConditionalExpressionImpl {
  Expression getCondition() { result = super.getCondition() }

  Expression getThen() { result = super.getThen() }

  Expression getElse() { result = super.getElse() }
}

final class ForExpression extends Expression instanceof ForExpressionImpl {
  Initializer getInitializer() { result = super.getInitializer() }

  Expression getCondition() { result = super.getCondition() }

  Expression getStep() { result = super.getStep() }

  Expression getBody() { result = super.getBody() }
}

final class FunctionCallExpression extends Expression instanceof FunctionCallExpressionImpl {
  Identifier getCallee() { result = super.getCallee() }

  Expression getArgument(int index) { result = super.getArgument(index) }
}

final class Number extends Expression instanceof NumberImpl {
  string getValue() { result = super.getValue() }
}

final class NumberLiteral extends Number instanceof NumberLiteralImpl { }

final private class DefaultStep extends Number instanceof DefaultStepImpl { }

final class ParenExpression extends Expression instanceof ParenExpressionImpl {
  Expression getExpression() { result = super.getExpression() }
}

final class UnaryOpExpression extends Expression instanceof UnaryOpExpressionImpl {
  Expression getOperand() { result = super.getOperand() }

  Identifier getOperator() { result = super.getOperator() }
}

final class VarInExpression extends Expression instanceof VarInExpressionImpl {
  Initializer getInitializer(int index) { result = super.getInitializer(index) }

  Expression getBody() { result = super.getBody() }
}

final class VariableExpression extends Expression instanceof VariableExpressionImpl {
  Identifier getVariable() { result = super.getVariable() }
}

final class Identifier extends AstNode instanceof IdentifierImpl {
  string getName() { result = super.getName() }
}

final class Initializer extends AstNode instanceof InitializerImpl {
  Identifier getVariable() { result = super.getVariable() }

  Expression getExpression() { result = super.getExpression() }
}

final class Prototype extends AstNode instanceof PrototypeImpl {
  Identifier getIdentifier() { result = super.getIdentifier() }

  Identifier getArgument(int index) { result = super.getArgument(index) }
}

final class BinaryPrototype extends Prototype instanceof BinaryPrototypeImpl {
  NumberLiteral getPrecedence() { result = super.getPrecedence() }
}

final class UnaryPrototype extends Prototype instanceof UnaryPrototypeImpl {
  Identifier getArgument() { result = this.getArgument(0) }
}

final class FunctionPrototype extends Prototype instanceof FunctionPrototypeImpl { }

final class Statement extends AstNode instanceof StatementImpl { }

final class Declaration extends Statement instanceof DeclarationImpl {
  Prototype getPrototype() { result = super.getPrototype() }
}

final class FunctionDefinition extends Declaration instanceof FunctionDefinitionImpl {
  Expression getBody() { result = super.getBody() }
}

final class ExternalDeclaration extends Declaration instanceof ExternalDeclarationImpl { }

final class Program extends AstNode instanceof ProgramImpl {
  Statement getStatement(int index) { result = super.getStatement(index) }
}
