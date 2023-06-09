private import codeql.kaleidoscope.ast.internal.TreeSitter::Kaleidoscope
private import ControlFlowGraphImplShared
import codeql.Locations
private import codeql.kaleidoscope.controlflow.BasicBlocks

private newtype TCompletion =
  TSimpleCompletion() or
  TBooleanCompletion(boolean b) { b in [false, true] } or
  TReturnCompletion()

abstract class Completion extends TCompletion {
  abstract string toString();

  predicate isValidForSpecific(ControlFlowElement e) { none() }

  predicate isValidFor(ControlFlowElement e) { this.isValidForSpecific(e) }

  abstract SuccessorType getAMatchingSuccessorType();
}

class SimpleCompletion extends Completion, TSimpleCompletion {
  override string toString() { result = "SimpleCompletion" }

  override predicate isValidFor(ControlFlowElement e) {
    not any(Completion c).isValidForSpecific(e)
  }

  override NormalSuccessor getAMatchingSuccessorType() { any() }
}

class BooleanCompletion extends Completion, TBooleanCompletion {
  boolean value;

  BooleanCompletion() { this = TBooleanCompletion(value) }

  override string toString() { result = "BooleanCompletion(" + value + ")" }

  override predicate isValidForSpecific(ControlFlowElement e) {
    e = any(ConditionalExpressionTree c).getCondition() or
    e = any(ForExpression c).getCondition()
  }

  override BooleanSuccessor getAMatchingSuccessorType() { result.getValue() = value }

  final boolean getValue() { result = value }
}

class ReturnCompletion extends Completion, TReturnCompletion {
  override string toString() { result = "ReturnCompletion" }

  override predicate isValidForSpecific(ControlFlowElement e) { none() }

  override ReturnSuccessor getAMatchingSuccessorType() { any() }
}

class ControlFlowElement = AstNode;

class ControlFlowTreeBase = ControlFlowElement;

predicate completionIsNormal(Completion c) { not c instanceof ReturnCompletion }

predicate completionIsSimple(Completion c) { c instanceof SimpleCompletion }

predicate completionIsValidFor(Completion c, ControlFlowElement e) { c.isValidFor(e) }

CfgScope getCfgScope(ControlFlowElement e) {
  exists(AstNode p | p = e.getParent() |
    result = p
    or
    not p instanceof CfgScope and result = getCfgScope(p)
  )
}

abstract class CfgScope extends AstNode { }

private class FunctionScope extends CfgScope, FunctionDefinition { }

private class ProgramScope extends CfgScope, Program { }

// Not using CFG splitting, so the following are just a dummy types.
private newtype TUnit = Unit()

class SplitKindBase = TUnit;

class Split extends TUnit {
  abstract string toString();
}

int maxSplits() { result = 0 }

predicate scopeFirst(CfgScope scope, ControlFlowElement e) {
  first(scope.(Program), e) or
  first(scope.(FunctionDefinition).getBody(), e)
}

predicate scopeLast(CfgScope scope, ControlFlowElement e, Completion c) {
  last(scope.(Program), e, c) or
  last(scope.(FunctionDefinition).getBody(), e, c)
}

cached
newtype TSuccessorType =
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

predicate successorTypeIsSimple(SuccessorType t) { t instanceof NormalSuccessor }

SuccessorType getAMatchingSuccessorType(Completion c) { result = c.getAMatchingSuccessorType() }

predicate isAbnormalExitType(SuccessorType t) { none() }

class Node extends TCfgNode {
  string toString() { none() }

  Location getLocation() { none() }

  final File getFile() { result = this.getLocation().getFile() }

  ControlFlowElement getNode() { none() }

  final predicate isCondition() { exists(this.getASuccessor(any(BooleanSuccessor bs))) }

  final CfgScope getScope() { result = this.getBasicBlock().getScope() }

  BasicBlock getBasicBlock() { result.getANode() = this }

  final ControlFlowNode getASuccessor(SuccessorType t) { result = getASuccessor(this, t) }

  final ControlFlowNode getASuccessor() { result = this.getASuccessor(_) }

  final ControlFlowNode getAPredecessor(SuccessorType t) { result.getASuccessor(t) = this }

  final ControlFlowNode getAPredecessor() { result = this.getAPredecessor(_) }

  final predicate isJoin() { strictcount(this.getAPredecessor()) > 1 }

  final predicate isBranch() { strictcount(this.getASuccessor()) > 1 }
}

/** An entry node for a given scope. */
class EntryNode extends ControlFlowNode, TEntryNode {
  private CfgScope scope;

  EntryNode() { this = TEntryNode(scope) }

  final override EntryBasicBlock getBasicBlock() { result = ControlFlowNode.super.getBasicBlock() }

  final override Location getLocation() { result = scope.getLocation() }

  final override string toString() { result = "enter " + scope }
}

/** An exit node for a given scope, annotated with the type of exit. */
class AnnotatedExitNode extends ControlFlowNode, TAnnotatedExitNode {
  private CfgScope scope;
  private boolean normal;

  AnnotatedExitNode() { this = TAnnotatedExitNode(scope, normal) }

  /** Holds if this node represent a normal exit. */
  final predicate isNormal() { normal = true }

  final override AnnotatedExitBasicBlock getBasicBlock() {
    result = ControlFlowNode.super.getBasicBlock()
  }

  final override Location getLocation() { result = scope.getLocation() }

  final override string toString() {
    exists(string s |
      normal = true and s = "normal"
      or
      normal = false and s = "abnormal"
    |
      result = "exit " + scope + " (" + s + ")"
    )
  }
}

/** An exit node for a given scope. */
class ExitNode extends ControlFlowNode, TExitNode {
  private CfgScope scope;

  ExitNode() { this = TExitNode(scope) }

  final override Location getLocation() { result = scope.getLocation() }

  final override string toString() { result = "exit " + scope }
}

/**
 * A node for an AST node.
 *
 * Each AST node maps to zero or more `ElementNode`s: zero when the node is unreachable
 * (dead) code or not important for control flow, and multiple when there are different
 * splits for the AST node.
 */
class ElementNode extends ControlFlowNode, TElementNode {
  private Splits splits;
  ControlFlowElement n;

  ElementNode() { this = TElementNode(_, n, splits) }

  final override ControlFlowElement getNode() { result = n }

  override Location getLocation() { result = n.getLocation() }

  final override string toString() {
    exists(string s | s = n.toString() |
      result = "[" + this.getSplitsString() + "] " + s
      or
      not exists(this.getSplitsString()) and result = s
    )
  }

  /** Gets a comma-separated list of strings for each split in this node, if any. */
  final string getSplitsString() {
    result = splits.toString() and
    result != ""
  }

  /** Gets a split for this control flow node, if any. */
  final Split getASplit() { result = splits.getASplit() }
}

class ControlFlowNode = Node;

private class ProgramTree extends StandardPreOrderTree, Program {
  override ControlFlowTree getChildElement(int i) { result = this.getStatement(i) }
}

private class FunctionDefinitionTree extends FunctionDefinition, LeafTree { }

private class FunctionCallExpressionTree extends StandardPostOrderTree, FunctionCallExpression {
  override ControlFlowTree getChildElement(int i) { result = this.getArgument(i) }
}

private class BinaryOpExpressionTree extends StandardPostOrderTree, BinaryOpExpression {
  override ControlFlowTree getChildElement(int i) {
    result = this.getLhs() and i = 0
    or
    result = this.getRhs() and i = 1
  }
}

private class ConditionalExpressionTree extends PostOrderTree, ConditionalExpression {
  override predicate propagatesAbnormal(ControlFlowElement child) { none() }

  override predicate first(ControlFlowElement first) { first(this.getCondition(), first) }

  override predicate succ(ControlFlowElement pred, ControlFlowElement succ, Completion c) {
    last(this.getCondition(), pred, c) and
    (
      first(this.getThen(), succ) and c.(BooleanCompletion).getValue() = true
      or
      first(this.getElse(), succ) and c.(BooleanCompletion).getValue() = false
    )
    or
    last(this.getThen(), pred, c) and
    succ = this and
    c instanceof SimpleCompletion
    or
    last(this.getElse(), pred, c) and
    succ = this and
    c instanceof SimpleCompletion
  }
}

private class ExternalDeclarationTree extends ExternalDeclaration, LeafTree { }

private class ForExpressionTree extends PostOrderTree, ForExpression {
  override predicate propagatesAbnormal(ControlFlowElement child) { none() }

  override predicate first(ControlFlowElement first) { first(this.getInitializer(), first) }

  override predicate succ(ControlFlowElement pred, ControlFlowElement succ, Completion c) {
    last(this.getInitializer(), pred, c) and
    first(this.getCondition(), succ) and
    c instanceof SimpleCompletion
    or
    last(this.getCondition(), pred, c) and
    (
      first(this.getBody(), succ) and c.(BooleanCompletion).getValue() = true
      or
      succ = this and c.(BooleanCompletion).getValue() = false
    )
    or
    last(this.getBody(), pred, c) and
    first(this.getUpdate(), succ) and
    c instanceof SimpleCompletion
    or
    last(this.getUpdate(), pred, c) and
    first(this.getCondition(), succ) and
    c instanceof SimpleCompletion
    or
    not exists(this.getUpdate()) and
    last(this.getBody(), pred, c) and
    first(this.getCondition(), succ) and
    c instanceof SimpleCompletion
  }
}

private class InitializerTree extends StandardPostOrderTree, Initializer {
  override ControlFlowTree getChildElement(int i) { result = this.getExpr() and i = 0 }
}

private class NumberTree extends Number, LeafTree { }

private class ParenExpressionTree extends StandardPostOrderTree, ParenExpression {
  override ControlFlowTree getChildElement(int i) { result = this.getExpr() and i = 0 }
}

private class UnaryOpExpressionTree extends StandardPostOrderTree, UnaryOpExpression {
  override ControlFlowTree getChildElement(int i) { result = this.getOperand() and i = 0 }
}

private class VarInExpressionTree extends StandardPostOrderTree, VarInExpression {
  override ControlFlowTree getChildElement(int i) {
    result = this.getInitializer(i)
    or
    result = this.getExpr() and i = count(this.getInitializer(_))
  }
}

private class VariableExpressionTree extends VariableExpression, LeafTree { }
