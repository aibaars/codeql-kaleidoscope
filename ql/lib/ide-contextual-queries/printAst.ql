/**
 * @name Print AST
 * @description Produces a representation of a file's Abstract Syntax Tree.
 *              This query is used by the VS Code extension.
 * @id kaleidoscope/print-ast
 * @kind graph
 * @tags ide-contextual-queries/print-ast
 */

import codeql.kaleidoscope.ideContextual.printAstGenerated
import codeql.kaleidoscope.ideContextual.IDEContextual

/**
 * Gets the source file to generate an AST from.
 */
external string selectedSourceFile();

// Overrides the configuration to print only nodes in the selected source file.
class Cfg extends PrintAstConfiguration {
  override predicate shouldPrintNode(AstNode n) {
    super.shouldPrintNode(n) and
    n.getLocation().getFile() = getFileBySourceArchiveName(selectedSourceFile())
  }
}
