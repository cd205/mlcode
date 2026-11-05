"""The sequence format and results JSON shared by the web app, the presets and the engine (web_app_plan.md C2, C6)."""

from oms.formats.results import run
from oms.formats.sequence_format import LoadedSequence, Reference, dump_sequence, load_sequence

__all__ = ["LoadedSequence", "Reference", "dump_sequence", "load_sequence", "run"]
