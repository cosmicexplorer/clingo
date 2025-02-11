# DO NOT EDIT THIS FILE! It was generated by scratch/mypy.py.

from typing import Collection, Generic, Optional, Protocol, TypeVar


C = TypeVar("C", bound="Comparable")


class Comparable(Protocol):
    def __lt__(self, other: C) -> bool: ...
    def __gt__(self, other: C) -> bool: ...
    def __le__(self, other: C) -> bool: ...
    def __ge__(self, other: C) -> bool: ...


Key = TypeVar('Key')
Value = TypeVar('Value')
class Lookup(Generic[Key], Collection[Value]):
    def __getitem__(self, key: Key) -> Optional[Value]: ...
