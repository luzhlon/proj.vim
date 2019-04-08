
from os import path
from denite.base.source import Base
from denite.kind.openable import Kind as Openable

class ProjKind(Openable):
    def __init__(self, vim):
        super().__init__(vim)

        self._vim = vim
        self.name = 'proj_path'
        self.default_action = 'open'

    def action_open(self, context):
        self._vim.vars['_'] = context['targets'][0]['word']
        self._vim.eval('proj#cd(g:_)')

class Source(Base):
    def __init__(self, vim):
        super().__init__(vim)

        self.name = 'proj'
        self.kind = ProjKind(vim)

    def gather_candidates(self, context):
        # If no menus have been defined, just exit
        history = self.vim.eval('proj#get_history()')
        if len(history) == 0:
            return []

        return [{'word': i} for i in history]
