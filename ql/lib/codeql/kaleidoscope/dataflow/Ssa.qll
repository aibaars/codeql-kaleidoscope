private import codeql.ssa.Ssa as SsaLib

private module Implementation implements SsaLib::InputSig {
  private import codeql.kaleidoscope.ast.internal.TreeSitter
  import codeql.kaleidoscope.controlflow.BasicBlocks

  BasicBlock getImmediateBasicBlockDominator(BasicBlock bb) { result = bb.getImmediateDominator() }

  BasicBlock getABasicBlockSuccessor(BasicBlock bb) { result = bb.getASuccessor() }

  /** A variable that can be SSA converted. */
  class SourceVariable extends Kaleidoscope::Identifier {
    SourceVariable() {
      this = any(Kaleidoscope::Initializer i).getVariable() or
      this = getPrototypeArgument(_)
    }
  }

  predicate variableWrite(BasicBlock bb, int i, SourceVariable v, boolean certain) {
    exists(Assignment assign | assign = bb.getNode(i).getNode() |
      v = lookupVar(assign.getVariable())
    ) and
    certain = true
    or
    certain = true and
    exists(EntryBasicBlock entry | bb = entry and i = 0 |
      v = getPrototypeArgument(entry.getScope().(Kaleidoscope::FunctionDefinition).getPrototype())
    )
  }

  predicate variableRead(BasicBlock bb, int i, SourceVariable v, boolean certain) {
    exists(Kaleidoscope::VariableExpression varExpr, Kaleidoscope::Identifier var |
      varExpr = bb.getNode(i).getNode() and
      varExpr.getName() = var and
      not var = any(Assignment a).getVariable()
    |
      v = lookupVar(var)
    ) and
    certain = true
  }

  abstract private class Assignment extends Kaleidoscope::AstNode {
    abstract Kaleidoscope::Identifier getVariable();
  }

  private class BinopAssignment extends Assignment instanceof Kaleidoscope::BinaryOpExpression {
    private Kaleidoscope::Identifier variable;

    BinopAssignment() {
      this.getOperator().getValue() = "=" and
      variable = super.getLhs().(Kaleidoscope::VariableExpression).getName()
    }

    override Kaleidoscope::Identifier getVariable() { result = variable }
  }

  private class InitializerAssignment extends Assignment instanceof Kaleidoscope::Initializer {
    override Kaleidoscope::Identifier getVariable() {
      result = Kaleidoscope::Initializer.super.getVariable()
    }
  }

  private class TVariableScope =
    @kaleidoscope_function_definition or @kaleidoscope_var_in_expression or
        @kaleidoscope_for_expression;

  private Kaleidoscope::Identifier getPrototypeArgument(Kaleidoscope::UnderscorePrototype proto) {
    result = proto.(Kaleidoscope::FunctionPrototype).getArgument(_) or
    result = proto.(Kaleidoscope::BinaryPrototype).getArgument(_) or
    result = proto.(Kaleidoscope::UnaryPrototype).getArgument()
  }

  private class VariableScope extends TVariableScope, Kaleidoscope::AstNode {
    VariableScope getEnclosingScope() { result = getVariableScope(this) }

    SourceVariable getVariable(string name) {
      exists(Kaleidoscope::Initializer decl |
        decl = this.(Kaleidoscope::VarInExpression).getInitializer(_) or
        decl = this.(Kaleidoscope::ForExpression).getInitializer()
      |
        result = decl.getVariable() and
        result.getValue() = name
      )
      or
      exists(Kaleidoscope::UnderscorePrototype p |
        p = this.(Kaleidoscope::FunctionDefinition).getPrototype() and
        result.getValue() = name and
        result = getPrototypeArgument(p)
      )
    }
  }

  private Kaleidoscope::AstNode parentOf(Kaleidoscope::AstNode n) {
    result = n.getParent() and not n instanceof TVariableScope
  }

  private VariableScope getVariableScope(Kaleidoscope::AstNode n) {
    result = parentOf*(n.getParent())
  }

  private SourceVariable lookupVar(Kaleidoscope::Identifier var) {
    result = lookupVar(getVariableScope(var), var.getValue())
  }

  private SourceVariable lookupVar(VariableScope scope, string name) {
    result = scope.getVariable(name)
    or
    not exists(scope.getVariable(name)) and result = lookupVar(scope.getEnclosingScope(), name)
  }
}

import SsaLib::Make<Implementation>
