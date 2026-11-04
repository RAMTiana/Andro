String _two(int n) => n.toString().padLeft(2, '0');

String fmtDate(DateTime d) => '${_two(d.day)}/${_two(d.month)}/${d.year}';

String fmtDateTime(DateTime d) =>
    '${_two(d.day)}/${_two(d.month)} ${_two(d.hour)}:${_two(d.minute)}';
