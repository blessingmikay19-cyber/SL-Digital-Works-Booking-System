// South Africa has no daylight saving, so SAST is always UTC+2.
DateTime toSast(DateTime time) => time.toUtc().add(const Duration(hours: 2));

String hm(DateTime d) =>
    '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

String dayLabel(DateTime d) {
  const wd = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  const mo = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${wd[d.weekday - 1]}, ${d.day} ${mo[d.month - 1]} ${d.year}';
}
