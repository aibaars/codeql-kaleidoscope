private import codeql.ssa.Ssa as SsaLib
private import codeql.kaleidoscope.controlflow.BasicBlocks
private import codeql.Locations
private import codeql.kaleidoscope.Cfg as Cfg
private import codeql.kaleidoscope.Ast

private class Assignment extends AstNode {
  private Identifier variable;

  Assignment() {
    this =
      any(BinaryOpExpression e |
        e.getOperator().getName() = "=" and
        variable = e.getLhs().(VariableExpression).getVariable()
      ) or
    variable = this.(Initializer).getVariable()
  }

  Identifier getVariable() { result = variable }

  Expression getValue() {
    this =
      any(BinaryOpExpression e |
        e.getOperator().getName() = "=" and
        result = e.getRhs()
      ) or
    result = this.(Initializer).getExpression()
  }
}

private module Implementation implements SsaLib::InputSig {
  import codeql.kaleidoscope.controlflow.BasicBlocks

  BasicBlock getImmediateBasicBlockDominator(BasicBlock bb) { result = bb.getImmediateDominator() }

  BasicBlock getABasicBlockSuccessor(BasicBlock bb) { result = bb.getASuccessor() }

  /** A variable that can be SSA converted. */
  class SourceVariable extends Identifier {
    SourceVariable() {
      this = any(Initializer i).getVariable() or
      this = any(Prototype p).getArgument(_)
    }
  }

  predicate variableWrite(BasicBlock bb, int i, SourceVariable v, boolean certain) {
    certain = true and
    exists(Assignment assign |
      assign = bb.getNode(i).getAstNode() and
      v = lookupVar(assign.getVariable())
    )
    or
    certain = true and
    exists(EntryBasicBlock entry | bb = entry and i = 0 |
      v = entry.getScope().(FunctionDefinition).getPrototype().getArgument(_)
    )
    or
    certain = true and
    exists(ForExpression for | for.getStep() = bb.getNode(i).getAstNode() |
      v = lookupVar(for.getInitializer().getVariable())
    )
  }

  predicate variableRead(BasicBlock bb, int i, SourceVariable v, boolean certain) {
    certain = true and
    exists(VariableExpression varExpr, Identifier var |
      varExpr = bb.getNode(i).getAstNode() and
      varExpr.getVariable() = var and
      not var = any(Assignment a).getVariable()
    |
      v = lookupVar(var)
    )
    or
    certain = true and
    exists(ForExpression for | for.getStep() = bb.getNode(i).getAstNode() |
      v = lookupVar(for.getInitializer().getVariable())
    )
  }

  private class VariableScope extends AstNode {
    VariableScope() {
      this instanceof FunctionDefinition or
      this instanceof VarInExpression or
      this instanceof ForExpression
    }

    VariableScope getEnclosingScope() { result = getVariableScope(this) }

    SourceVariable getVariable(string name) {
      exists(Initializer decl |
        decl = this.(VarInExpression).getInitializer(_) or
        decl = this.(ForExpression).getInitializer()
      |
        result = decl.getVariable() and
        result.getName() = name
      )
      or
      exists(Prototype p |
        p = this.(FunctionDefinition).getPrototype() and
        result.getName() = name and
        result = p.getArgument(_)
      )
    }
  }

  private AstNode parentOf(AstNode n) { result = n.getParent() and not n instanceof VariableScope }

  private VariableScope getVariableScope(AstNode n) { result = parentOf*(n.getParent()) }

  private SourceVariable lookupVar(Identifier var) {
    result = lookupVar(getVariableScope(var), var.getName())
  }

  private SourceVariable lookupVar(VariableScope scope, string name) {
    result = scope.getVariable(name)
    or
    not exists(scope.getVariable(name)) and result = lookupVar(scope.getEnclosingScope(), name)
  }
}

private import SsaLib::Make<Implementation> as SsaImpl

cached
class Definition extends SsaImpl::Definition {
  cached
  Location getLocation() { none() }

  cached
  Cfg::Node getARead() {
    exists(Implementation::SourceVariable v, Implementation::BasicBlock bb, int i |
      SsaImpl::ssaDefReachesRead(v, this, bb, i) and
      Implementation::variableRead(bb, i, v, true) and
      result = bb.getNode(i)
    )
  }

  cached
  Cfg::Node getAFirstRead() {
    exists(Implementation::BasicBlock bb1, int i1, Implementation::BasicBlock bb2, int i2 |
      this.definesAt(_, bb1, i1) and
      SsaImpl::adjacentDefRead(this, bb1, i1, bb2, i2) and
      result = bb2.getNode(i2)
    )
  }

  cached
  predicate adjacentReadPair(Cfg::Node read1, Cfg::Node read2) {
    exists(Implementation::BasicBlock bb1, int i1, Implementation::BasicBlock bb2, int i2 |
      read1 = bb1.getNode(i1) and
      Implementation::variableRead(bb1, i1, _, true) and
      SsaImpl::adjacentDefRead(this, bb1, i1, bb2, i2) and
      read2 = bb2.getNode(i2)
    )
  }

  cached
  predicate lastRefRedef(Implementation::BasicBlock bb, int i, Definition next) {
    SsaImpl::lastRefRedef(this, bb, i, next)
  }
}

cached
class WriteDefinition extends Definition, SsaImpl::WriteDefinition {
  cached
  override Location getLocation() {
    exists(Implementation::BasicBlock bb, int i |
      this.definesAt(_, bb, i) and
      result = bb.getNode(i).getLocation()
    )
  }

  /**
   * Holds if this SSA definition represents a direct assignment of `value`
   * to the underlying variable.
   */
  cached
  predicate assigns(Cfg::Node value) {
    exists(Assignment a, Implementation::BasicBlock bb, int i |
      this.definesAt(_, bb, i) and
      a = bb.getNode(i).getAstNode() and
      value.getAstNode() = a.getValue()
    )
  }
}

cached
class PhiDefinition extends Definition, SsaImpl::PhiNode {
  cached
  override Location getLocation() {
    exists(Implementation::BasicBlock bb |
      this.definesAt(_, bb, _) and
      result = bb.getLocation()
    )
  }

  cached
  Definition getPhiInput(Implementation::BasicBlock bb) {
    SsaImpl::phiHasInputFromBlock(this, result, bb)
  }

  cached
  Definition getAPhiInput() { result = this.getPhiInput(_) }
}
