/**
 * @kind graph
 * @id kd/controlflow/cfg
 */

private import codeql.kaleidoscope.controlflow.internal.ControlFlowGraphImplShared::TestOutput

class MyRelevantNode extends RelevantNode {
  MyRelevantNode() { exists(this) }
}
