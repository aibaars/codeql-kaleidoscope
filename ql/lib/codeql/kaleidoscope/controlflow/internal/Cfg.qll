private import codeql.kaleidoscope.Ast
private import codeql.controlflow.Cfg as CfgShared
private import codeql.Locations

module Completion {
  private newtype TCompletion =
    TSimpleCompletion() or
    TBooleanCompletion(boolean b) { b in [false, true] } or
    TReturnCompletion()

  abstract class Completion extends TCompletion {
    abstract string toString();

    predicate isValidForSpecific(AstNode e) { none() }

    predicate isValidFor(AstNode e) { this.isValidForSpecific(e) }

    abstract SuccessorType getAMatchingSuccessorType();
  }

  abstract class NormalCompletion extends Completion { }

  class SimpleCompletion extends NormalCompletion, TSimpleCompletion {
    override string toString() { result = "SimpleCompletion" }

    override predicate isValidFor(AstNode e) { not any(Completion c).isValidForSpecific(e) }

    override NormalSuccessor getAMatchingSuccessorType() { any() }
  }

  class BooleanCompletion extends NormalCompletion, TBooleanCompletion {
    boolean value;

    BooleanCompletion() { this = TBooleanCompletion(value) }

    override string toString() { result = "BooleanCompletion(" + value + ")" }

    override predicate isValidForSpecific(AstNode e) {
      e = any(ConditionalExpression c).getCondition() or
      e = any(ForExpression c).getCondition()
    }

    override BooleanSuccessor getAMatchingSuccessorType() { result.getValue() = value }

    final boolean getValue() { result = value }
  }

  class ReturnCompletion extends Completion, TReturnCompletion {
    override string toString() { result = "ReturnCompletion" }

    override predicate isValidForSpecific(AstNode e) { none() }

    override ReturnSuccessor getAMatchingSuccessorType() { any() }
  }

  cached
  private newtype TSuccessorType =
    TNormalSuccessor() or
    TBooleanSuccessor(boolean b) { b in [false, true] } or
    TReturnSuccessor()

  class SuccessorType extends TSuccessorType {
    string toString() { none() }
  }

  class NormalSuccessor extends SuccessorType, TNormalSuccessor {
    override string toString() { result = "successor" }
  }

  class BooleanSuccessor extends SuccessorType, TBooleanSuccessor {
    boolean value;

    BooleanSuccessor() { this = TBooleanSuccessor(value) }

    override string toString() { result = value.toString() }

    boolean getValue() { result = value }
  }

  class ReturnSuccessor extends SuccessorType, TReturnSuccessor {
    override string toString() { result = "return" }
  }
}

module CfgScope {
  abstract class CfgScope extends AstNode { }

  private class FunctionScope extends CfgScope, FunctionDefinition { }

  private class ProgramScope extends CfgScope, Program { }
}

private module Implementation implements CfgShared::InputSig<Location> {
  import codeql.kaleidoscope.Ast
  import Completion
  import CfgScope

  predicate completionIsNormal(Completion c) { not c instanceof ReturnCompletion }

  // Not using CFG splitting, so the following are just dummy types.
  private newtype TUnit = Unit()

  class SplitKindBase = TUnit;

  class Split extends TUnit {
    abstract string toString();
  }

  predicate completionIsSimple(Completion c) { c instanceof SimpleCompletion }

  predicate completionIsValidFor(Completion c, AstNode e) { c.isValidFor(e) }

  CfgScope getCfgScope(AstNode e) {
    exists(AstNode p | p = e.getParent() |
      result = p
      or
      not p instanceof CfgScope and result = getCfgScope(p)
    )
  }

  int maxSplits() { result = 0 }

  predicate scopeFirst(CfgScope scope, AstNode e) {
    first(scope.(Program), e) or
    first(scope.(FunctionDefinition).getBody(), e)
  }

  predicate scopeLast(CfgScope scope, AstNode e, Completion c) {
    last(scope.(Program), e, c) or
    last(scope.(FunctionDefinition).getBody(), e, c)
  }

  predicate successorTypeIsSimple(SuccessorType t) { t instanceof NormalSuccessor }

  predicate successorTypeIsCondition(SuccessorType t) { t instanceof BooleanSuccessor }

  SuccessorType getAMatchingSuccessorType(Completion c) { result = c.getAMatchingSuccessorType() }

  predicate isAbnormalExitType(SuccessorType t) { none() }
}

module CfgImpl = CfgShared::Make<Location, Implementation>;

private import CfgImpl
private import Completion
private import CfgScope

private class ProgramTree extends StandardPreOrderTree instanceof Program {
  override ControlFlowTree getChildNode(int i) { result = super.getStatement(i) }
}

private class FunctionDefinitionTree extends LeafTree instanceof FunctionDefinition { }

private class FunctionCallExpressionTree extends StandardPostOrderTree instanceof FunctionCallExpression
{
  override ControlFlowTree getChildNode(int i) { result = super.getArgument(i) }
}

private class BinaryOpExpressionTree extends StandardPostOrderTree instanceof BinaryOpExpression {
  override ControlFlowTree getChildNode(int i) {
    result = super.getLhs() and i = 0
    or
    result = super.getRhs() and i = 1
  }
}

private class ConditionalExpressionTree extends PostOrderTree instanceof ConditionalExpression {
  override predicate propagatesAbnormal(AstNode child) { none() }

  override predicate first(AstNode first) { first(super.getCondition(), first) }

  override predicate succ(AstNode pred, AstNode succ, Completion c) {
    last(super.getCondition(), pred, c) and
    (
      first(super.getThen(), succ) and c.(BooleanCompletion).getValue() = true
      or
      first(super.getElse(), succ) and c.(BooleanCompletion).getValue() = false
    )
    or
    last(super.getThen(), pred, c) and
    succ = this and
    c instanceof SimpleCompletion
    or
    last(super.getElse(), pred, c) and
    succ = this and
    c instanceof SimpleCompletion
  }
}

private class ExternalDeclarationTree extends LeafTree instanceof ExternalDeclaration { }

/**
 * From https://llvm.org/docs/tutorial/MyFirstLanguageFrontend/LangImpl05.html#code-generation-for-the-for-loop in the LLVM tutorial it appears that
 * for loop conditions are checked at the end of the body, not the start. So for loops are roughly translated as follows:
 * ```
 * for VAR = INIT, CONDITION, STEP in
 *   BODY
 * ```
 * -->
 * ```
 * VAR = INIT
 * do {
 *   BODY
 *   VAR = VAR + STEP
 * } while (CONDITION)
 * ```
 */
private class ForExpressionTree extends PostOrderTree instanceof ForExpression {
  override predicate propagatesAbnormal(AstNode child) { none() }

  override predicate first(AstNode first) { first(super.getInitializer(), first) }

  override predicate succ(AstNode pred, AstNode succ, Completion c) {
    last(super.getInitializer(), pred, c) and
    first(super.getBody(), succ) and
    c instanceof SimpleCompletion
    or
    last(super.getCondition(), pred, c) and
    (
      first(super.getBody(), succ) and c.(BooleanCompletion).getValue() = true
      or
      succ = this and c.(BooleanCompletion).getValue() = false
    )
    or
    last(super.getBody(), pred, c) and
    first(super.getStep(), succ) and
    c instanceof SimpleCompletion
    or
    last(super.getStep(), pred, c) and
    first(super.getCondition(), succ) and
    c instanceof SimpleCompletion
  }
}

private class InitializerTree extends StandardPostOrderTree instanceof Initializer {
  override ControlFlowTree getChildNode(int i) { result = super.getExpression() and i = 0 }
}

private class NumberTree extends LeafTree instanceof Number { }

private class ParenExpressionTree extends StandardPostOrderTree instanceof ParenExpression {
  override ControlFlowTree getChildNode(int i) { result = super.getExpression() and i = 0 }
}

private class UnaryOpExpressionTree extends StandardPostOrderTree instanceof UnaryOpExpression {
  override ControlFlowTree getChildNode(int i) { result = super.getOperand() and i = 0 }
}

private class VarInExpressionTree extends StandardPostOrderTree instanceof VarInExpression {
  override ControlFlowTree getChildNode(int i) {
    result = super.getInitializer(i)
    or
    result = super.getBody() and i = count(super.getInitializer(_))
  }
}

private class VariableExpressionTree extends LeafTree instanceof VariableExpression { }
