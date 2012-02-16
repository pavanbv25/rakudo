use NQPP6Regex;

# This walks the PAST tree and adds sink context annotations.
class Perl6::Sinker {
    method sink($past) {
        self.visit_children($past);
    }
    
    # Called when we encounter a block in the tree.
    method visit_block($block) {
        $block.blocktype eq 'declaration'
        ?? $block
        !! self.visit_children($block);
    }

    method visit_stmts($st) {
        my $i := 0;
        while $i < +@($st) - 1 {
            $st[$i] := self.visit_children($st[$i]);
            $i++;
        }
        $st;
    }
    
    # Called when we encounter a PAST::Op in the tree. Produces either
    # the op itself or some replacement opcode to put in the tree.
    method visit_op($op) {
        return $op if $op<nosink>;
        if  $op.pasttype eq 'call'
         || $op.pasttype eq 'callmethod'
         || !$op.pasttype {
            PAST::Op.new(:name('&sink'), $op);
        } else {
            $op;
        }
    }
    
    # Handles visiting a PAST::Want node.
    method visit_want($want) {
        self.visit_children($want)
    }
    
    # Handles visit a variable node.
    method visit_var($var) {
        $var
    }
    
    # Visits all of a nodes children, and dispatches appropriately.
    method visit_children($node) {
        my $i := 0;
        while $i < +@($node) {
            my $visit := $node[$i];
            unless pir::isa($visit, 'String') || pir::isa($visit, 'Integer') || pir::isa($visit, 'Float') {
                if $visit.isa(PAST::Op) {
                    $node[$i] := self.visit_op($visit)
                }
                elsif $visit.isa(PAST::Block) {
                    $node[$i] := self.visit_block($visit);
                }
                elsif $visit.isa(PAST::Stmts) {
                    $node[$i] := self.visit_stmts($visit);
                }
                elsif $visit.isa(PAST::Stmt) {
                    $node[$i] := self.visit_stmts($visit);
                }
                elsif $visit.isa(PAST::Want) {
                    $node[$i] := self.visit_want($visit);
                }
                elsif $visit.isa(PAST::Var) {
                    $node[$i] := self.visit_var($visit);
                }
                elsif $visit.isa(PAST::Val) {
                    # don't do anything on literals
                }
            }
            $i := $i + 1;
        }
        $node;
    }
}