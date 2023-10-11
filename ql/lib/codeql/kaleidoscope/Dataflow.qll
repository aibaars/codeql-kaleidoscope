private import codeql.dataflow.DataFlow
private import codeql.kaleidoscope.Ast
private import codeql.kaleidoscope.Cfg as Cfg
private import codeql.kaleidoscope.dataflow.Ssa as Ssa
private import codeql.Locations

private module Private {
  cached
  newtype TNode =
    TExprNode(DataFlowExpr e) or
    TReturningNode(Cfg::Node n) { n.getAstNode() = any(FunctionDefinition d).getBody() } or
    TSsaDefinitionNode(Ssa::Definition def) or
    TParameterNode(Identifier p) { p = any(FunctionDefinition d).getPrototype().getArgument(_) }

  class DataFlowExpr extends Cfg::Node {
    DataFlowExpr() { this.getAstNode() instanceof Expression }
  }

  class ParameterPosition extends int {
    ParameterPosition() { this = [0, 1] or exists(any(Prototype e).getArgument(this)) }
  }

  class ArgumentPosition extends int {
    ArgumentPosition() { this = [0, 1] or exists(any(FunctionCallExpression e).getArgument(this)) }
  }

  predicate parameterMatch(ParameterPosition ppos, ArgumentPosition apos) { ppos = apos }

  class DataFlowCall instanceof Cfg::Node {
    DataFlowCall() {
      super.getAstNode() instanceof FunctionCallExpression or
      super.getAstNode() instanceof BinaryOpExpression or
      super.getAstNode() instanceof UnaryOpExpression
    }

    /** Gets a textual representation of this element. */
    string toString() { result = super.toString() }

    Location getLocation() { result = super.getLocation() }

    string getName() {
      result = super.getAstNode().(FunctionCallExpression).getCallee().getName() or
      result = super.getAstNode().(BinaryOpExpression).getOperator().getName() or
      result = super.getAstNode().(UnaryOpExpression).getOperator().getName()
    }

    DataFlowCallable getEnclosingCallable() { result = super.getScope() }
  }

  class DataFlowCallable instanceof Cfg::CfgScope {
    string toString() { result = super.toString() }

    Location getLocation() { result = super.getLocation() }

    string getName() { result = this.(FunctionDefinition).getPrototype().getIdentifier().getName() }
  }

  private newtype TDataFlowType = TUnknownDataFlowType()

  class DataFlowType extends TDataFlowType {
    string toString() { result = "" }
  }
}

private module Public {
  private import Private

  class Node extends TNode {
    /** Gets a textual representation of this element. */
    string toString() { none() }

    Location getLocation() { none() }

    /**
     * Holds if this element is at the specified location.
     * The location spans column `startcolumn` of line `startline` to
     * column `endcolumn` of line `endline` in file `filepath`.
     * For more information, see
     * [Locations](https://codeql.github.com/docs/writing-codeql-queries/providing-locations-in-codeql-queries/).
     */
    predicate hasLocationInfo(
      string filepath, int startline, int startcolumn, int endline, int endcolumn
    ) {
      this.getLocation().hasLocationInfo(filepath, startline, startcolumn, endline, endcolumn)
    }
  }

  class ExprNode extends Node, TExprNode {
    private DataFlowExpr expr;

    ExprNode() { this = TExprNode(expr) }

    Cfg::Node getCfgNode() { result = expr }

    override string toString() { result = expr.toString() }

    override Location getLocation() { result = expr.getLocation() }
  }

  class ParameterNode extends Node, TParameterNode {
    private Identifier parameter;

    ParameterNode() { this = TParameterNode(parameter) }

    predicate isParameterOf(DataFlowCallable c, ParameterPosition pos) {
      parameter = c.(FunctionDefinition).getPrototype().getArgument(pos)
    }

    override string toString() { result = parameter.toString() }

    override Location getLocation() { result = parameter.getLocation() }

    Identifier getParameter() { result = parameter }
  }

  class ArgumentNode extends ExprNode {
    ArgumentNode() {
      this.getCfgNode().getAstNode() = any(FunctionCallExpression e).getArgument(_) or
      this.getCfgNode().getAstNode() = any(BinaryOpExpression e).getLhs() or
      this.getCfgNode().getAstNode() = any(BinaryOpExpression e).getRhs() or
      this.getCfgNode().getAstNode() = any(UnaryOpExpression e).getOperand()
    }

    predicate argumentOf(DataFlowCall call, ArgumentPosition pos) {
      this.getCfgNode() = call.(Cfg::Node).getAPredecessor+() and
      (
        call.(Cfg::Node).getAstNode() =
          any(FunctionCallExpression e | e.getArgument(pos) = this.getCfgNode().getAstNode()) or
        call.(Cfg::Node).getAstNode() =
          any(BinaryOpExpression e |
            pos = 0 and e.getLhs() = this.getCfgNode().getAstNode()
            or
            pos = 1 and e.getRhs() = this.getCfgNode().getAstNode()
          ) or
        call.(Cfg::Node).getAstNode() =
          any(UnaryOpExpression e | pos = 0 and e.getOperand() = this.getCfgNode().getAstNode())
      )
    }
  }

  class ReturnNode extends Node, TReturningNode {
    private Cfg::Node node;

    ReturnNode() { this = TReturningNode(node) }

    ReturnKind getKind() { result = TNormalReturn() }

    override string toString() { result = "return " + node.toString() }

    override Location getLocation() { result = node.getLocation() }
  }

  private newtype TReturnKind = TNormalReturn()

  abstract class ReturnKind extends TReturnKind {
    /** Gets a textual representation of this element. */
    abstract string toString();
  }

  class NormalReturn extends ReturnKind, TNormalReturn {
    override string toString() { result = "return" }
  }

  /**
   */
  class SsaDefinitionNode extends Node, TSsaDefinitionNode {
    Ssa::Definition def;

    SsaDefinitionNode() { this = TSsaDefinitionNode(def) }

    Ssa::Definition asDefinition() { result = def }

    override string toString() { result = def.toString() }

    override Location getLocation() { result = def.getLocation() }
  }

  predicate simpleLocalFlowStep(Node nodeFrom, Node nodeTo) {
    LocalFlow::localFlowStep(nodeFrom, nodeTo)
    or
    LocalFlow::localSsaFlowStep(nodeFrom, nodeTo)
  }
}

private module LocalFlow {
  private import Public
  private import codeql.kaleidoscope.controlflow.BasicBlocks

  private predicate localSsaFlowStepUseUse(Ssa::Definition def, ExprNode nodeFrom, ExprNode nodeTo) {
    def.adjacentReadPair(nodeFrom.getCfgNode(), nodeTo.getCfgNode())
  }

  private predicate localFlowSsaInput(
    SsaDefinitionNode nodeFrom, Ssa::Definition def, Ssa::Definition next
  ) {
    exists(BasicBlock bb, int i | def.lastRefRedef(bb, i, next) |
      def.definesAt(_, bb, i) and
      def = nodeFrom.asDefinition()
    )
  }

  /**
   * Holds if `nodeFrom` is a parameter node, and `nodeTo` is a corresponding SSA node.
   */
  private predicate localFlowSsaParamInput(ParameterNode nodeFrom, SsaDefinitionNode nodeTo) {
    nodeTo.asDefinition().definesAt(nodeFrom.getParameter(), _, _)
  }

  /**
   * Holds if there is a local flow step from `nodeFrom` to `nodeTo` involving
   * SSA.
   */
  predicate localSsaFlowStep(Node nodeFrom, Node nodeTo) {
    exists(Ssa::Definition def |
      // Step from assignment RHS to def
      def.(Ssa::WriteDefinition).assigns(nodeFrom.(ExprNode).getCfgNode()) and
      nodeTo.(SsaDefinitionNode).asDefinition() = def
      or
      // step from def to first read
      nodeFrom.(SsaDefinitionNode).asDefinition() = def and
      nodeTo.(ExprNode).getCfgNode() = def.getAFirstRead()
      or
      // use-use flow
      localSsaFlowStepUseUse(def, nodeFrom, nodeTo)
      or
      // step from previous read to Phi node
      localFlowSsaInput(nodeFrom, def, nodeTo.(SsaDefinitionNode).asDefinition())
    )
    or
    localFlowSsaParamInput(nodeFrom, nodeTo)
  }

  pragma[nomagic]
  predicate localFlowStep(Node nodeFrom, Node nodeTo) {
    //  Parenthesized expression
    nodeTo.(ExprNode).getCfgNode() = nodeFrom.(ExprNode).getCfgNode().getASuccessor() and
    nodeTo.(ExprNode).getCfgNode().getAstNode().(ParenExpression).getExpression() =
      nodeFrom.(ExprNode).getCfgNode().getAstNode()
    or
    // Conditional expression
    exists(ConditionalExpression c |
      c = nodeTo.(ExprNode).getCfgNode().getAstNode() and
      nodeTo.(ExprNode).getCfgNode() = nodeFrom.(ExprNode).getCfgNode().getASuccessor() and
      nodeFrom.(ExprNode).getCfgNode().getAstNode() = [c.getThen(), c.getElse()]
    )
    or
    //  VarIn expression
    nodeTo.(ExprNode).getCfgNode() = nodeFrom.(ExprNode).getCfgNode().getASuccessor() and
    nodeTo.(ExprNode).getCfgNode().getAstNode().(VarInExpression).getBody() =
      nodeFrom.(ExprNode).getCfgNode().getAstNode()
  }
}

private module Implementation implements InputSig {
  import Public
  import Private

  class OutNode extends ExprNode {
    private DataFlowCall call;

    OutNode() { call = this.getCfgNode() }

    DataFlowCall getCall(ReturnKind kind) {
      result = call and
      kind instanceof NormalReturn
    }
  }

  class PostUpdateNode extends Node {
    PostUpdateNode() { none() }

    Node getPreUpdateNode() { none() }
  }

  class CastNode extends Node {
    CastNode() { none() }
  }

  predicate isParameterNode(ParameterNode p, DataFlowCallable c, ParameterPosition pos) {
    p.isParameterOf(c, pos)
  }

  predicate isArgumentNode(ArgumentNode arg, DataFlowCall call, ArgumentPosition pos) {
    arg.argumentOf(call, pos)
  }

  DataFlowCallable nodeGetEnclosingCallable(Node node) {
    node = TExprNode(any(DataFlowExpr e | result = e.getScope())) or
    node = TReturningNode(any(Cfg::Node n | result = n.getScope())) or
    node = TSsaDefinitionNode(any(Ssa::Definition def | result = def.getBasicBlock().getScope())) or
    node =
      TParameterNode(any(Identifier p |
          p = result.(FunctionDefinition).getPrototype().getArgument(_)
        ))
  }

  DataFlowType getNodeType(Node node) { any() }

  predicate nodeIsHidden(Node node) { none() }

  /** Gets the node corresponding to `e`. */
  Node exprNode(DataFlowExpr e) { result = TExprNode(e) }

  /** Gets a viable implementation of the target of the given `Call`. */
  DataFlowCallable viableCallable(DataFlowCall c) {
    // TODO: improve to cover redefined functions
    c.getName() = result.getName()
  }

  /**
   * Holds if the set of viable implementations that can be called by `call`
   * might be improved by knowing the call context.
   */
  predicate mayBenefitFromCallContext(DataFlowCall call, DataFlowCallable c) { none() }

  /**
   * Gets a viable dispatch target of `call` in the context `ctx`. This is
   * restricted to those `call`s for which a context might make a difference.
   */
  DataFlowCallable viableImplInCallContext(DataFlowCall call, DataFlowCall ctx) { none() }

  /**
   * Gets a node that can read the value returned from `call` with return kind
   * `kind`.
   */
  OutNode getAnOutNode(DataFlowCall call, ReturnKind kind) { call = result.getCall(kind) }

  string ppReprType(DataFlowType t) { none() }

  bindingset[t1, t2]
  predicate compatibleTypes(DataFlowType t1, DataFlowType t2) { t1 = t2 }

  predicate typeStrongerThan(DataFlowType t1, DataFlowType t2) { none() }

  private newtype TContent = TNoContent() { none() }

  class Content extends TContent {
    /** Gets a textual representation of this element. */
    string toString() { none() }
  }

  predicate forceHighPrecision(Content c) { none() }

  private newtype TContentSet = TNoContentSet() { none() }

  /**
   * An entity that represents a set of `Content`s.
   *
   * The set may be interpreted differently depending on whether it is
   * stored into (`getAStoreContent`) or read from (`getAReadContent`).
   */
  class ContentSet extends TContentSet {
    /** Gets a textual representation of this element. */
    string toString() { none() }

    /** Gets a content that may be stored into when storing into this set. */
    Content getAStoreContent() { none() }

    /** Gets a content that may be read from when reading from this set. */
    Content getAReadContent() { none() }
  }

  private newtype TContentApprox = TNoContentApprox() { none() }

  class ContentApprox extends TContentApprox {
    /** Gets a textual representation of this element. */
    string toString() { none() }
  }

  ContentApprox getContentApprox(Content c) { none() }

  /**
   * Holds if data can flow from `node1` to `node2` through a non-local step
   * that does not follow a call edge. For example, a step through a global
   * variable.
   */
  predicate jumpStep(Node node1, Node node2) { none() }

  /**
   * Holds if data can flow from `node1` to `node2` via a read of `c`.  Thus,
   * `node1` references an object with a content `c.getAReadContent()` whose
   * value ends up in `node2`.
   */
  predicate readStep(Node node1, ContentSet c, Node node2) { none() }

  /**
   * Holds if data can flow from `node1` to `node2` via a store into `c`.  Thus,
   * `node2` references an object with a content `c.getAStoreContent()` that
   * contains the value of `node1`.
   */
  predicate storeStep(Node node1, ContentSet c, Node node2) { none() }

  /**
   * Holds if values stored inside content `c` are cleared at node `n`. For example,
   * any value stored inside `f` is cleared at the pre-update node associated with `x`
   * in `x.f = newValue`.
   */
  predicate clearsContent(Node n, ContentSet c) { none() }

  /**
   * Holds if the value that is being tracked is expected to be stored inside content `c`
   * at node `n`.
   */
  predicate expectsContent(Node n, ContentSet c) { none() }

  /**
   * Holds if the node `n` is unreachable when the call context is `call`.
   */
  predicate isUnreachableInCall(Node n, DataFlowCall call) { none() }

  /**
   * Holds if flow is allowed to pass from parameter `p` and back to itself as a
   * side-effect, resulting in a summary from `p` to itself.
   *
   * One example would be to allow flow like `p.foo = p.bar;`, which is disallowed
   * by default as a heuristic.
   */
  predicate allowParameterReturnInSelf(ParameterNode p) { none() }

  private newtype TLambdaCallKind = TNone()

  class LambdaCallKind = TLambdaCallKind;

  /** Holds if `creation` is an expression that creates a lambda of kind `kind` for `c`. */
  predicate lambdaCreation(Node creation, LambdaCallKind kind, DataFlowCallable c) { none() }

  /** Holds if `call` is a lambda call of kind `kind` where `receiver` is the lambda expression. */
  predicate lambdaCall(DataFlowCall call, LambdaCallKind kind, Node receiver) { none() }

  /** Extra data-flow steps needed for lambda flow analysis. */
  predicate additionalLambdaFlowStep(Node nodeFrom, Node nodeTo, boolean preservesValue) { none() }

  /**
   * Gets an additional term that is added to the `join` and `branch` computations to reflect
   * an additional forward or backwards branching factor that is not taken into account
   * when calculating the (virtual) dispatch cost.
   *
   * Argument `arg` is part of a path from a source to a sink, and `p` is the target parameter.
   */
  int getAdditionalFlowIntoCallNodeTerm(ArgumentNode arg, ParameterNode p) { none() }

  predicate golangSpecificParamArgFilter(DataFlowCall call, ParameterNode p, ArgumentNode arg) {
    any()
  }
}

module Dataflow {
  import DataFlowMake<Implementation>
  import Public
}
