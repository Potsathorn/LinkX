enum ChannelLabel {
  marketingOneLink('Marketing (OneLink)', 'Marketing'),
  chatVoiceBot('Chat/Voice bot', 'Chat/Voice'),
  pushNotification('Push Noti', 'Push Noti'),
  unreferenced('Not referenced by any channel source', 'Unref');

  const ChannelLabel(this.raw, this.shortLabel);

  final String raw;
  final String shortLabel;

  bool get isActiveChannel => this != ChannelLabel.unreferenced;

  static ChannelLabel? fromRaw(String value) {
    final String normalized = value.trim();
    for (final ChannelLabel label in ChannelLabel.values) {
      if (label.raw == normalized) return label;
    }
    return null;
  }

  static List<ChannelLabel> parseList(List<dynamic> raw) {
    final List<ChannelLabel> result = <ChannelLabel>[];
    for (final dynamic value in raw) {
      final ChannelLabel? label = fromRaw(value.toString());
      if (label != null && !result.contains(label)) result.add(label);
    }
    result.sort((ChannelLabel a, ChannelLabel b) => a.index.compareTo(b.index));
    return result;
  }
}
