class DynamicResolvedEventDate {
  const DynamicResolvedEventDate({
    required this.month,
    required this.day,
    this.endMonth,
    this.endDay,
    this.durationDays = 1,
  });

  final int month;
  final int day;
  final int? endMonth;
  final int? endDay;
  final int durationDays;
}

const Map<int, Map<String, DynamicResolvedEventDate>> kResolvedLunarEventDates = {
  2026: <String, DynamicResolvedEventDate>{
    'guru_gobind_singh_jayanti': DynamicResolvedEventDate(month: 1, day: 5),
    'nagoba_jatara': DynamicResolvedEventDate(month: 1, day: 18, durationDays: 9),
    'tyagaraja_aradhana': DynamicResolvedEventDate(month: 1, day: 19, durationDays: 7),
    'ratha_saptami': DynamicResolvedEventDate(month: 1, day: 25),
    'sammakka_saralamma_jatara_medaram_jatara':
        DynamicResolvedEventDate(month: 1, day: 28, durationDays: 4),
    'maha_shivaratri': DynamicResolvedEventDate(month: 2, day: 15),
    'holi': DynamicResolvedEventDate(month: 3, day: 4),
    'ugadi': DynamicResolvedEventDate(month: 3, day: 19),
    'sri_rama_navami': DynamicResolvedEventDate(month: 3, day: 27),
    'bhadrachalam_sri_rama_kalyanam': DynamicResolvedEventDate(month: 3, day: 27),
    'sri_ramanavami_sita_rama_kalyanam_usage':
        DynamicResolvedEventDate(month: 3, day: 27),
    'mahavir_jayanti': DynamicResolvedEventDate(month: 3, day: 31),
    'hanuman_jayanthi': DynamicResolvedEventDate(month: 4, day: 2),
    'anjaneya_swamy_jayanti_usage': DynamicResolvedEventDate(month: 4, day: 2),
    'basava_jayanti': DynamicResolvedEventDate(month: 4, day: 20),
    'simhachalam_chandanotsavam': DynamicResolvedEventDate(month: 4, day: 20),
    'narasimha_jayanthi': DynamicResolvedEventDate(month: 4, day: 30),
    'sri_narasimha_jayanti_usage': DynamicResolvedEventDate(month: 4, day: 30),
    'bonalu': DynamicResolvedEventDate(month: 6, day: 26, durationDays: 29),
    'varalakshmi_vratham': DynamicResolvedEventDate(month: 8, day: 28),
    'krishna_janmashtami': DynamicResolvedEventDate(month: 9, day: 4),
    'vinayaka_chavithi': DynamicResolvedEventDate(month: 9, day: 14),
    'tirumala_brahmotsavam': DynamicResolvedEventDate(month: 9, day: 15, durationDays: 9),
    'kanaka_durga_temple_dasara':
        DynamicResolvedEventDate(month: 9, day: 22, endMonth: 10, endDay: 2),
    'bathukamma': DynamicResolvedEventDate(month: 10, day: 12, durationDays: 9),
    'dasara_vijayadashami': DynamicResolvedEventDate(month: 10, day: 20),
    'deepavali': DynamicResolvedEventDate(month: 11, day: 8),
    'guru_nanak_jayanti': DynamicResolvedEventDate(month: 11, day: 24),
    'karthika_pournami_karthika_deepam':
        DynamicResolvedEventDate(month: 11, day: 24),
    'vaikuntha_ekadashi': DynamicResolvedEventDate(month: 12, day: 20),
  },
};
