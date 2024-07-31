/**
 * @kind graph
 * @id kd/controlflow/cfg
 */

private import codeql.kaleidoscope.Cfg::TestOutput

class MyRelevantNode extends RelevantNode {
  MyRelevantNode() { exists(this) }
}
