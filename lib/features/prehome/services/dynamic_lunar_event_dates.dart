import 'package:cloud_firestore/cloud_firestore.dart';

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

const Map<int, Map<String, DynamicResolvedEventDate>>
kResolvedLunarEventDates = {
  2026: <String, DynamicResolvedEventDate>{
    'additional_day_durga_puja_west_bengal': DynamicResolvedEventDate(
      month: 10,
      day: 22,
      endMonth: 10,
      endDay: 24,
    ),
    'additional_day_kali_puja_west_bengal': DynamicResolvedEventDate(
      month: 11,
      day: 9,
      endMonth: 11,
      endDay: 10,
    ),
    'additional_day_lakshmi_puja_west_bengal': DynamicResolvedEventDate(
      month: 10,
      day: 26,
    ),
    'agrasen_jayanti_chhattisgarh': DynamicResolvedEventDate(
      month: 10,
      day: 11,
    ),
    'akheri_chahar_sumba_tripura': DynamicResolvedEventDate(month: 8, day: 12),
    'akshaya_tritiya': DynamicResolvedEventDate(month: 5, day: 9),
    'anjaneya_swamy_jayanti_usage': DynamicResolvedEventDate(month: 4, day: 2),
    'arbayeen_chahallum': DynamicResolvedEventDate(month: 8, day: 4),
    'atla_taddi': DynamicResolvedEventDate(month: 10, day: 28),
    'babu_jagjivan_ram_jayanthi': DynamicResolvedEventDate(month: 4, day: 5),
    'bakrid_eid_ul_adha': DynamicResolvedEventDate(month: 5, day: 27),
    'basanti_puja_tripura': DynamicResolvedEventDate(month: 3, day: 25),
    'basava_jayanti': DynamicResolvedEventDate(month: 4, day: 20),
    'bathukamma': DynamicResolvedEventDate(month: 10, day: 12, durationDays: 9),
    'bathukamma_starting_day': DynamicResolvedEventDate(month: 10, day: 10),
    'bhadrachalam_sri_rama_kalyanam': DynamicResolvedEventDate(
      month: 3,
      day: 27,
    ),
    'bhai_dooj': DynamicResolvedEventDate(month: 10, day: 31),
    'bhakt_mata_karma_jayanti_chhattisgarh': DynamicResolvedEventDate(
      month: 3,
      day: 15,
    ),
    'bhishma_ekadashi': DynamicResolvedEventDate(month: 2, day: 28),
    'bhogali_bihu': DynamicResolvedEventDate(month: 1, day: 14),
    'bhogi': DynamicResolvedEventDate(month: 1, day: 14),
    'biju_buisu_festival_tripura': DynamicResolvedEventDate(month: 4, day: 14),
    'birthday_hazrath_syed_mohammed_juvanpuri': DynamicResolvedEventDate(
      month: 10,
      day: 26,
    ),
    'birthday_kazi_nazrul_islam_tripura': DynamicResolvedEventDate(
      month: 5,
      day: 26,
    ),
    'bonalu': DynamicResolvedEventDate(month: 7, day: 19, durationDays: 23),
    'buddha_purnima': DynamicResolvedEventDate(month: 5, day: 1),
    'chaitra_pournami': DynamicResolvedEventDate(month: 4, day: 2),
    'chhath_puja': DynamicResolvedEventDate(month: 11, day: 3),
    'dasara_vijayadashami': DynamicResolvedEventDate(month: 10, day: 20),
    'datta_jayanthi': DynamicResolvedEventDate(month: 12, day: 23),
    'deepavali': DynamicResolvedEventDate(month: 11, day: 8),
    'dev_diwali': DynamicResolvedEventDate(month: 11, day: 24),
    'devotional_karthika_masam_start_usage': DynamicResolvedEventDate(
      month: 10,
      day: 31,
    ),
    'dhol_gyaras_chhattisgarh': DynamicResolvedEventDate(month: 9, day: 22),
    'dr_b_r_ambedkar_jayanthi': DynamicResolvedEventDate(month: 4, day: 14),
    'durga_puja_west_bengal': DynamicResolvedEventDate(
      month: 10,
      day: 17,
      endMonth: 10,
      endDay: 24,
    ),
    'eid_e_ghadeer': DynamicResolvedEventDate(month: 6, day: 4),
    'eid_ul_fitr_ramzan': DynamicResolvedEventDate(month: 3, day: 21),
    'fathers_day': DynamicResolvedEventDate(month: 6, day: 21),
    'first_onam_kerala': DynamicResolvedEventDate(month: 8, day: 25),
    'following_day_of_ramzan': DynamicResolvedEventDate(month: 3, day: 22),
    'following_day_of_vijaya_dasami': DynamicResolvedEventDate(
      month: 10,
      day: 21,
    ),
    'fourth_onam_kerala': DynamicResolvedEventDate(month: 8, day: 28),
    'friendship_day': DynamicResolvedEventDate(month: 8, day: 2),
    'garia_puja': DynamicResolvedEventDate(month: 4, day: 21),
    'good_friday': DynamicResolvedEventDate(month: 4, day: 3),
    'guru_gobind_singh_jayanti': DynamicResolvedEventDate(month: 1, day: 5),
    'guru_nanak_jayanti': DynamicResolvedEventDate(month: 11, day: 24),
    'guru_pournima': DynamicResolvedEventDate(month: 7, day: 29),
    'hanuman_jayanthi': DynamicResolvedEventDate(month: 4, day: 2),
    'harchhath_chhattisgarh': DynamicResolvedEventDate(month: 9, day: 2),
    'hareli': DynamicResolvedEventDate(month: 8, day: 12),
    'holi': DynamicResolvedEventDate(month: 3, day: 4),
    'holika_dahan_holi_eve_usage': DynamicResolvedEventDate(month: 3, day: 21),
    'hul_diwas_west_bengal': DynamicResolvedEventDate(month: 6, day: 30),
    'indigenous_faith_day_arunachal': DynamicResolvedEventDate(
      month: 12,
      day: 1,
    ),
    'jamai_sasthi_tripura': DynamicResolvedEventDate(month: 6, day: 20),
    'jamatul_vida': DynamicResolvedEventDate(month: 3, day: 13),
    'jhulan_jatra_samapan_tripura': DynamicResolvedEventDate(month: 8, day: 28),
    'kali_puja_west_bengal': DynamicResolvedEventDate(
      month: 11,
      day: 8,
      endMonth: 11,
      endDay: 10,
    ),
    'kanaka_durga_temple_dasara': DynamicResolvedEventDate(
      month: 9,
      day: 22,
      endMonth: 10,
      endDay: 2,
    ),
    'kanuma': DynamicResolvedEventDate(month: 1, day: 16),
    'karkidaka_vavu': DynamicResolvedEventDate(month: 8, day: 12),
    'karthika_pournami_karthika_deepam': DynamicResolvedEventDate(
      month: 11,
      day: 24,
    ),
    'karwa_chauth': DynamicResolvedEventDate(month: 10, day: 29),
    'ker_puja': DynamicResolvedEventDate(month: 8, day: 4),
    'kharchi_puja': DynamicResolvedEventDate(month: 7, day: 22),
    'krishna_janmashtami': DynamicResolvedEventDate(month: 9, day: 4),
    'kubera_puja': DynamicResolvedEventDate(month: 11, day: 6),
    'maa_shakambhri_jayanti_cherchera_chhattisgarh': DynamicResolvedEventDate(
      month: 1,
      day: 3,
    ),
    'maha_shivaratri': DynamicResolvedEventDate(month: 2, day: 15),
    'mahalaya_amavasya': DynamicResolvedEventDate(month: 10, day: 10),
    'maharaja_bir_bikram_jayanthi_tripura': DynamicResolvedEventDate(
      month: 8,
      day: 19,
    ),
    'mahavir_jayanti': DynamicResolvedEventDate(month: 3, day: 31),
    'makara_sankranti': DynamicResolvedEventDate(month: 1, day: 15),
    'milad_un_nabi': DynamicResolvedEventDate(month: 8, day: 26),
    'mothers_day': DynamicResolvedEventDate(month: 5, day: 10),
    'muharram_ashura': DynamicResolvedEventDate(month: 6, day: 26),
    'naga_panchami': DynamicResolvedEventDate(month: 8, day: 17),
    'nagoba_jatara': DynamicResolvedEventDate(
      month: 1,
      day: 18,
      durationDays: 9,
    ),
    'namdev_jayanti_chhattisgarh': DynamicResolvedEventDate(month: 11, day: 20),
    'naraka_chaturdasi': DynamicResolvedEventDate(month: 10, day: 28),
    'narasimha_jayanthi': DynamicResolvedEventDate(month: 4, day: 30),
    'nawa_khai_chhattisgarh': DynamicResolvedEventDate(month: 9, day: 18),
    'onam': DynamicResolvedEventDate(month: 8, day: 26),
    'peerla_panduga_usage': DynamicResolvedEventDate(month: 6, day: 16),
    'poet_bhanu_bhakt_jayanthi_west_bengal': DynamicResolvedEventDate(
      month: 7,
      day: 13,
    ),
    'pola_chhattisgarh': DynamicResolvedEventDate(month: 9, day: 10),
    'polala_amma_vratam': DynamicResolvedEventDate(month: 9, day: 11),
    'pous_parban_tripura': DynamicResolvedEventDate(month: 1, day: 14),
    'raksha_bandhan_sravana_purnima': DynamicResolvedEventDate(
      month: 8,
      day: 18,
    ),
    'rath_yatra': DynamicResolvedEventDate(month: 7, day: 16),
    'ratha_saptami': DynamicResolvedEventDate(month: 1, day: 25),
    'saddula_bathukamma_maha_saptami': DynamicResolvedEventDate(
      month: 10,
      day: 18,
    ),
    'sahastrabahu_jayanti_chhattisgarh': DynamicResolvedEventDate(
      month: 11,
      day: 16,
    ),
    'sammakka_saralamma_jatara_medaram_jatara': DynamicResolvedEventDate(
      month: 1,
      day: 28,
      durationDays: 4,
    ),
    'saraswati_puja_west_bengal': DynamicResolvedEventDate(month: 1, day: 23),
    'sarv_pitru_moksha_amavasya_chhattisgarh': DynamicResolvedEventDate(
      month: 10,
      day: 10,
    ),
    'shab_e_barat': DynamicResolvedEventDate(month: 2, day: 4),
    'shab_e_meraj': DynamicResolvedEventDate(month: 1, day: 17),
    'shab_e_qadar': DynamicResolvedEventDate(month: 3, day: 17),
    'shahadat_hazrath_ali': DynamicResolvedEventDate(month: 3, day: 10),
    'shahid_vir_narayan_singh_balidan_diwas_chhattisgarh':
        DynamicResolvedEventDate(month: 12, day: 10),
    'shri_shri_harichand_thakur_jayanthi_west_bengal': DynamicResolvedEventDate(
      month: 3,
      day: 17,
    ),
    'simhachalam_chandanotsavam': DynamicResolvedEventDate(month: 4, day: 20),
    'songrongma_puja_tripura': DynamicResolvedEventDate(month: 9, day: 11),
    'sri_narasimha_jayanti_usage': DynamicResolvedEventDate(month: 4, day: 30),
    'sri_panchami_vasanth_panchami': DynamicResolvedEventDate(
      month: 1,
      day: 23,
    ),
    'sri_rama_navami': DynamicResolvedEventDate(month: 3, day: 27),
    'sri_ramanavami_sita_rama_kalyanam_usage': DynamicResolvedEventDate(
      month: 3,
      day: 27,
    ),
    'srisailam_maha_shivaratri_brahmotsavam': DynamicResolvedEventDate(
      month: 2,
      day: 27,
      endMonth: 3,
      endDay: 9,
      durationDays: 11,
    ),
    'st_theresa_festival_puducherry': DynamicResolvedEventDate(
      month: 10,
      day: 15,
    ),
    'thakur_panchanan_barma_jayanthi_west_bengal': DynamicResolvedEventDate(
      month: 2,
      day: 14,
    ),
    'third_onam_kerala': DynamicResolvedEventDate(month: 8, day: 27),
    'thiruvalluvar_day_mattu_pongal_puducherry': DynamicResolvedEventDate(
      month: 1,
      day: 16,
    ),
    'tirumala_brahmotsavam': DynamicResolvedEventDate(
      month: 9,
      day: 15,
      durationDays: 9,
    ),
    'tulasi_vivaham': DynamicResolvedEventDate(month: 11, day: 21),
    'tyagaraja_aradhana': DynamicResolvedEventDate(
      month: 1,
      day: 19,
      durationDays: 7,
    ),
    'ugadi': DynamicResolvedEventDate(month: 3, day: 19),
    'ugadi_panchanga_sravanam': DynamicResolvedEventDate(month: 3, day: 19),
    'vaikuntha_ekadashi': DynamicResolvedEventDate(month: 12, day: 20),
    'valmiki_jayanti': DynamicResolvedEventDate(month: 10, day: 26),
    'varalakshmi_vratham': DynamicResolvedEventDate(month: 8, day: 21),
    'vinayaka_chavithi': DynamicResolvedEventDate(month: 9, day: 14),
    'vishu': DynamicResolvedEventDate(month: 4, day: 15),
    'vishva_adivasi_diwas_chhattisgarh': DynamicResolvedEventDate(
      month: 8,
      day: 9,
    ),
    'viswakarma_puja_west_bengal': DynamicResolvedEventDate(month: 9, day: 17),
    'world_first_aid_day': DynamicResolvedEventDate(month: 9, day: 12),
    'world_habitat_day': DynamicResolvedEventDate(month: 10, day: 5),
    'world_laughter_day': DynamicResolvedEventDate(month: 5, day: 3),
    'world_pangolin_day': DynamicResolvedEventDate(month: 2, day: 21),
    'world_river_day': DynamicResolvedEventDate(month: 9, day: 27),
    'yadadri_brahmotsavam': DynamicResolvedEventDate(
      month: 3,
      day: 18,
      durationDays: 11,
    ),
    'yaz_dahum_shareef': DynamicResolvedEventDate(month: 9, day: 23),
  },
  2027: <String, DynamicResolvedEventDate>{
    'makara_sankranti': DynamicResolvedEventDate(month: 1, day: 15),
    'ratha_saptami': DynamicResolvedEventDate(month: 2, day: 13),
    'maha_shivaratri': DynamicResolvedEventDate(month: 3, day: 6),
    'holi': DynamicResolvedEventDate(month: 3, day: 22),
    'ugadi': DynamicResolvedEventDate(month: 4, day: 7),
    'sri_rama_navami': DynamicResolvedEventDate(month: 4, day: 15),
    'hanuman_jayanthi': DynamicResolvedEventDate(month: 4, day: 20),
    'narasimha_jayanthi': DynamicResolvedEventDate(month: 5, day: 19),
    'bonalu': DynamicResolvedEventDate(month: 7, day: 11, durationDays: 28),
    'varalakshmi_vratham': DynamicResolvedEventDate(month: 8, day: 13),
    'krishna_janmashtami': DynamicResolvedEventDate(month: 8, day: 25),
    'vinayaka_chavithi': DynamicResolvedEventDate(month: 9, day: 4),
    'bathukamma': DynamicResolvedEventDate(
      month: 9,
      day: 30,
      endMonth: 10,
      endDay: 8,
      durationDays: 9,
    ),
    'dasara_vijayadashami': DynamicResolvedEventDate(month: 10, day: 10),
    'deepavali': DynamicResolvedEventDate(month: 10, day: 29),
    'karthika_pournami_karthika_deepam': DynamicResolvedEventDate(
      month: 11,
      day: 12,
    ),
    'vaikuntha_ekadashi': DynamicResolvedEventDate(month: 12, day: 19),
    'sammakka_saralamma_jatara_medaram_jatara': DynamicResolvedEventDate(
      month: 2,
      day: 17,
      durationDays: 4,
    ),
    'nagoba_jatara': DynamicResolvedEventDate(
      month: 1,
      day: 31,
      durationDays: 5,
    ),
    'guru_nanak_jayanti': DynamicResolvedEventDate(month: 11, day: 12),
    'tyagaraja_aradhana': DynamicResolvedEventDate(month: 1, day: 30),
    'basava_jayanti': DynamicResolvedEventDate(month: 5, day: 9),
    'mahavir_jayanti': DynamicResolvedEventDate(month: 4, day: 18),
    'kanaka_durga_temple_dasara': DynamicResolvedEventDate(
      month: 10,
      day: 2,
      endMonth: 10,
      endDay: 10,
      durationDays: 9,
    ),
    'tirumala_brahmotsavam': DynamicResolvedEventDate(
      month: 10,
      day: 1,
      durationDays: 9,
    ),
    'simhachalam_chandanotsavam': DynamicResolvedEventDate(month: 5, day: 9),
    'srisailam_maha_shivaratri_brahmotsavam': DynamicResolvedEventDate(
      month: 2,
      day: 27,
      endMonth: 3,
      endDay: 9,
      durationDays: 11,
    ),
    'yadadri_brahmotsavam': DynamicResolvedEventDate(
      month: 3,
      day: 18,
      durationDays: 11,
    ),
    'bhadrachalam_sri_rama_kalyanam': DynamicResolvedEventDate(
      month: 4,
      day: 15,
    ),
    'peerla_panduga_usage': DynamicResolvedEventDate(month: 6, day: 16),
    'sri_ramanavami_sita_rama_kalyanam_usage': DynamicResolvedEventDate(
      month: 4,
      day: 15,
    ),
    'anjaneya_swamy_jayanti_usage': DynamicResolvedEventDate(month: 4, day: 20),
    'sri_narasimha_jayanti_usage': DynamicResolvedEventDate(month: 5, day: 19),
    'devotional_karthika_masam_start_usage': DynamicResolvedEventDate(
      month: 10,
      day: 31,
    ),
    'holika_dahan_holi_eve_usage': DynamicResolvedEventDate(month: 3, day: 21),
    'eid_ul_fitr_ramzan': DynamicResolvedEventDate(month: 3, day: 10),
    'good_friday': DynamicResolvedEventDate(month: 3, day: 26),
    'akshaya_tritiya': DynamicResolvedEventDate(month: 5, day: 9),
    'buddha_purnima': DynamicResolvedEventDate(month: 5, day: 20),
    'bakrid_eid_ul_adha': DynamicResolvedEventDate(month: 5, day: 17),
    'muharram_ashura': DynamicResolvedEventDate(month: 6, day: 16),
    'rath_yatra': DynamicResolvedEventDate(month: 7, day: 6),
    'milad_un_nabi': DynamicResolvedEventDate(month: 7, day: 25),
    'raksha_bandhan_sravana_purnima': DynamicResolvedEventDate(
      month: 8,
      day: 18,
    ),
    'bathukamma_starting_day': DynamicResolvedEventDate(month: 9, day: 30),
    'saddula_bathukamma_maha_saptami': DynamicResolvedEventDate(
      month: 10,
      day: 8,
    ),
    'naraka_chaturdasi': DynamicResolvedEventDate(month: 10, day: 28),
    'bhai_dooj': DynamicResolvedEventDate(month: 10, day: 31),
    'chhath_puja': DynamicResolvedEventDate(month: 11, day: 3),
  },
  2028: <String, DynamicResolvedEventDate>{
    'makara_sankranti': DynamicResolvedEventDate(month: 1, day: 15),
    'ratha_saptami': DynamicResolvedEventDate(month: 2, day: 2),
    'maha_shivaratri': DynamicResolvedEventDate(month: 2, day: 23),
    'holi': DynamicResolvedEventDate(month: 3, day: 11),
    'ugadi': DynamicResolvedEventDate(month: 3, day: 27),
    'sri_rama_navami': DynamicResolvedEventDate(month: 4, day: 3),
    'hanuman_jayanthi': DynamicResolvedEventDate(month: 4, day: 9),
    'narasimha_jayanthi': DynamicResolvedEventDate(month: 5, day: 8),
    'bonalu': DynamicResolvedEventDate(month: 6, day: 25, durationDays: 35),
    'varalakshmi_vratham': DynamicResolvedEventDate(month: 8, day: 4),
    'krishna_janmashtami': DynamicResolvedEventDate(month: 8, day: 13),
    'vinayaka_chavithi': DynamicResolvedEventDate(month: 8, day: 23),
    'bathukamma': DynamicResolvedEventDate(
      month: 9,
      day: 19,
      endMonth: 9,
      endDay: 27,
      durationDays: 9,
    ),
    'dasara_vijayadashami': DynamicResolvedEventDate(month: 9, day: 30),
    'deepavali': DynamicResolvedEventDate(month: 10, day: 17),
    'karthika_pournami_karthika_deepam': DynamicResolvedEventDate(
      month: 11,
      day: 1,
    ),
    'vaikuntha_ekadashi': DynamicResolvedEventDate(month: 12, day: 8),
    'sammakka_saralamma_jatara_medaram_jatara': DynamicResolvedEventDate(
      month: 2,
      day: 2,
      durationDays: 4,
    ),
    'nagoba_jatara': DynamicResolvedEventDate(
      month: 1,
      day: 20,
      durationDays: 5,
    ),
    'guru_nanak_jayanti': DynamicResolvedEventDate(month: 11, day: 1),
    'tyagaraja_aradhana': DynamicResolvedEventDate(month: 1, day: 19),
    'basava_jayanti': DynamicResolvedEventDate(month: 4, day: 18),
    'mahavir_jayanti': DynamicResolvedEventDate(month: 4, day: 6),
    'kanaka_durga_temple_dasara': DynamicResolvedEventDate(
      month: 9,
      day: 22,
      endMonth: 9,
      endDay: 30,
      durationDays: 9,
    ),
    'tirumala_brahmotsavam': DynamicResolvedEventDate(
      month: 9,
      day: 20,
      durationDays: 9,
    ),
    'simhachalam_chandanotsavam': DynamicResolvedEventDate(month: 4, day: 18),
    'srisailam_maha_shivaratri_brahmotsavam': DynamicResolvedEventDate(
      month: 2,
      day: 14,
      endMonth: 2,
      endDay: 24,
      durationDays: 11,
    ),
    'yadadri_brahmotsavam': DynamicResolvedEventDate(
      month: 3,
      day: 8,
      durationDays: 11,
    ),
    'bhadrachalam_sri_rama_kalyanam': DynamicResolvedEventDate(
      month: 4,
      day: 3,
    ),
    'peerla_panduga_usage': DynamicResolvedEventDate(month: 6, day: 5),
    'sri_ramanavami_sita_rama_kalyanam_usage': DynamicResolvedEventDate(
      month: 4,
      day: 3,
    ),
    'anjaneya_swamy_jayanti_usage': DynamicResolvedEventDate(month: 4, day: 9),
    'sri_narasimha_jayanti_usage': DynamicResolvedEventDate(month: 5, day: 8),
    'devotional_karthika_masam_start_usage': DynamicResolvedEventDate(
      month: 10,
      day: 19,
    ),
    'holika_dahan_holi_eve_usage': DynamicResolvedEventDate(month: 3, day: 10),
    'eid_ul_fitr_ramzan': DynamicResolvedEventDate(month: 2, day: 27),
    'good_friday': DynamicResolvedEventDate(month: 4, day: 14),
    'akshaya_tritiya': DynamicResolvedEventDate(month: 4, day: 18),
    'buddha_purnima': DynamicResolvedEventDate(month: 5, day: 10),
    'bakrid_eid_ul_adha': DynamicResolvedEventDate(month: 5, day: 6),
    'muharram_ashura': DynamicResolvedEventDate(month: 6, day: 5),
    'rath_yatra': DynamicResolvedEventDate(month: 6, day: 24),
    'milad_un_nabi': DynamicResolvedEventDate(month: 7, day: 14),
    'raksha_bandhan_sravana_purnima': DynamicResolvedEventDate(
      month: 8,
      day: 7,
    ),
    'bathukamma_starting_day': DynamicResolvedEventDate(month: 9, day: 19),
    'saddula_bathukamma_maha_saptami': DynamicResolvedEventDate(
      month: 9,
      day: 27,
    ),
    'naraka_chaturdasi': DynamicResolvedEventDate(month: 10, day: 16),
    'bhai_dooj': DynamicResolvedEventDate(month: 10, day: 19),
    'chhath_puja': DynamicResolvedEventDate(month: 10, day: 22),
  },
  2029: <String, DynamicResolvedEventDate>{
    'makara_sankranti': DynamicResolvedEventDate(month: 1, day: 14),
    'ratha_saptami': DynamicResolvedEventDate(month: 1, day: 21),
    'maha_shivaratri': DynamicResolvedEventDate(month: 2, day: 11),
    'holi': DynamicResolvedEventDate(month: 3, day: 1),
    'ugadi': DynamicResolvedEventDate(month: 4, day: 14),
    'sri_rama_navami': DynamicResolvedEventDate(month: 4, day: 23),
    'hanuman_jayanthi': DynamicResolvedEventDate(month: 4, day: 28),
    'narasimha_jayanthi': DynamicResolvedEventDate(month: 5, day: 18),
    'bonalu': DynamicResolvedEventDate(month: 7, day: 15, durationDays: 28),
    'varalakshmi_vratham': DynamicResolvedEventDate(month: 8, day: 24),
    'krishna_janmashtami': DynamicResolvedEventDate(month: 9, day: 1),
    'vinayaka_chavithi': DynamicResolvedEventDate(month: 9, day: 12),
    'bathukamma': DynamicResolvedEventDate(
      month: 10,
      day: 8,
      endMonth: 10,
      endDay: 16,
      durationDays: 9,
    ),
    'dasara_vijayadashami': DynamicResolvedEventDate(month: 10, day: 18),
    'deepavali': DynamicResolvedEventDate(month: 11, day: 5),
    'karthika_pournami_karthika_deepam': DynamicResolvedEventDate(
      month: 11,
      day: 20,
    ),
    'vaikuntha_ekadashi': DynamicResolvedEventDate(month: 12, day: 27),
    'sammakka_saralamma_jatara_medaram_jatara': DynamicResolvedEventDate(
      month: 2,
      day: 21,
      durationDays: 4,
    ),
    'nagoba_jatara': DynamicResolvedEventDate(
      month: 2,
      day: 8,
      durationDays: 5,
    ),
    'guru_nanak_jayanti': DynamicResolvedEventDate(month: 11, day: 20),
    'tyagaraja_aradhana': DynamicResolvedEventDate(month: 2, day: 6),
    'basava_jayanti': DynamicResolvedEventDate(month: 5, day: 7),
    'mahavir_jayanti': DynamicResolvedEventDate(month: 4, day: 25),
    'kanaka_durga_temple_dasara': DynamicResolvedEventDate(
      month: 10,
      day: 10,
      endMonth: 10,
      endDay: 18,
      durationDays: 9,
    ),
    'tirumala_brahmotsavam': DynamicResolvedEventDate(
      month: 10,
      day: 9,
      durationDays: 9,
    ),
    'simhachalam_chandanotsavam': DynamicResolvedEventDate(month: 5, day: 7),
    'srisailam_maha_shivaratri_brahmotsavam': DynamicResolvedEventDate(
      month: 2,
      day: 2,
      endMonth: 2,
      endDay: 12,
      durationDays: 11,
    ),
    'yadadri_brahmotsavam': DynamicResolvedEventDate(
      month: 3,
      day: 26,
      durationDays: 11,
    ),
    'bhadrachalam_sri_rama_kalyanam': DynamicResolvedEventDate(
      month: 4,
      day: 23,
    ),
    'peerla_panduga_usage': DynamicResolvedEventDate(month: 5, day: 26),
    'sri_ramanavami_sita_rama_kalyanam_usage': DynamicResolvedEventDate(
      month: 4,
      day: 23,
    ),
    'anjaneya_swamy_jayanti_usage': DynamicResolvedEventDate(month: 4, day: 28),
    'sri_narasimha_jayanti_usage': DynamicResolvedEventDate(month: 5, day: 18),
    'devotional_karthika_masam_start_usage': DynamicResolvedEventDate(
      month: 11,
      day: 7,
    ),
    'holika_dahan_holi_eve_usage': DynamicResolvedEventDate(month: 2, day: 28),
    'eid_ul_fitr_ramzan': DynamicResolvedEventDate(month: 2, day: 15),
    'good_friday': DynamicResolvedEventDate(month: 3, day: 30),
    'akshaya_tritiya': DynamicResolvedEventDate(month: 5, day: 7),
    'buddha_purnima': DynamicResolvedEventDate(month: 5, day: 28),
    'bakrid_eid_ul_adha': DynamicResolvedEventDate(month: 4, day: 25),
    'muharram_ashura': DynamicResolvedEventDate(month: 5, day: 26),
    'rath_yatra': DynamicResolvedEventDate(month: 7, day: 13),
    'milad_un_nabi': DynamicResolvedEventDate(month: 7, day: 3),
    'raksha_bandhan_sravana_purnima': DynamicResolvedEventDate(
      month: 8,
      day: 27,
    ),
    'bathukamma_starting_day': DynamicResolvedEventDate(month: 10, day: 8),
    'saddula_bathukamma_maha_saptami': DynamicResolvedEventDate(
      month: 10,
      day: 16,
    ),
    'naraka_chaturdasi': DynamicResolvedEventDate(month: 11, day: 4),
    'bhai_dooj': DynamicResolvedEventDate(month: 11, day: 7),
    'chhath_puja': DynamicResolvedEventDate(month: 11, day: 10),
  },
  2030: <String, DynamicResolvedEventDate>{
    'makara_sankranti': DynamicResolvedEventDate(month: 1, day: 14),
    'ratha_saptami': DynamicResolvedEventDate(month: 2, day: 9),
    'maha_shivaratri': DynamicResolvedEventDate(month: 3, day: 2),
    'holi': DynamicResolvedEventDate(month: 3, day: 20),
    'ugadi': DynamicResolvedEventDate(month: 4, day: 3),
    'sri_rama_navami': DynamicResolvedEventDate(month: 4, day: 12),
    'hanuman_jayanthi': DynamicResolvedEventDate(month: 4, day: 17),
    'narasimha_jayanthi': DynamicResolvedEventDate(month: 5, day: 6),
    'bonalu': DynamicResolvedEventDate(month: 7, day: 7, durationDays: 28),
    'varalakshmi_vratham': DynamicResolvedEventDate(month: 8, day: 9),
    'krishna_janmashtami': DynamicResolvedEventDate(month: 8, day: 22),
    'vinayaka_chavithi': DynamicResolvedEventDate(month: 9, day: 1),
    'bathukamma': DynamicResolvedEventDate(
      month: 9,
      day: 27,
      endMonth: 10,
      endDay: 5,
      durationDays: 9,
    ),
    'dasara_vijayadashami': DynamicResolvedEventDate(month: 10, day: 7),
    'deepavali': DynamicResolvedEventDate(month: 10, day: 26),
    'karthika_pournami_karthika_deepam': DynamicResolvedEventDate(
      month: 11,
      day: 9,
    ),
    'vaikuntha_ekadashi': DynamicResolvedEventDate(month: 12, day: 17),
    'sammakka_saralamma_jatara_medaram_jatara': DynamicResolvedEventDate(
      month: 2,
      day: 10,
      durationDays: 4,
    ),
    'nagoba_jatara': DynamicResolvedEventDate(
      month: 1,
      day: 28,
      durationDays: 5,
    ),
    'guru_nanak_jayanti': DynamicResolvedEventDate(month: 11, day: 9),
    'tyagaraja_aradhana': DynamicResolvedEventDate(month: 1, day: 27),
    'basava_jayanti': DynamicResolvedEventDate(month: 4, day: 27),
    'mahavir_jayanti': DynamicResolvedEventDate(month: 4, day: 14),
    'kanaka_durga_temple_dasara': DynamicResolvedEventDate(
      month: 9,
      day: 29,
      endMonth: 10,
      endDay: 7,
      durationDays: 9,
    ),
    'tirumala_brahmotsavam': DynamicResolvedEventDate(
      month: 9,
      day: 28,
      durationDays: 9,
    ),
    'simhachalam_chandanotsavam': DynamicResolvedEventDate(month: 4, day: 27),
    'srisailam_maha_shivaratri_brahmotsavam': DynamicResolvedEventDate(
      month: 2,
      day: 21,
      endMonth: 3,
      endDay: 3,
      durationDays: 11,
    ),
    'yadadri_brahmotsavam': DynamicResolvedEventDate(
      month: 3,
      day: 15,
      durationDays: 11,
    ),
    'bhadrachalam_sri_rama_kalyanam': DynamicResolvedEventDate(
      month: 4,
      day: 12,
    ),
    'peerla_panduga_usage': DynamicResolvedEventDate(month: 5, day: 15),
    'sri_ramanavami_sita_rama_kalyanam_usage': DynamicResolvedEventDate(
      month: 4,
      day: 12,
    ),
    'anjaneya_swamy_jayanti_usage': DynamicResolvedEventDate(month: 4, day: 17),
    'sri_narasimha_jayanti_usage': DynamicResolvedEventDate(month: 5, day: 6),
    'devotional_karthika_masam_start_usage': DynamicResolvedEventDate(
      month: 10,
      day: 28,
    ),
    'holika_dahan_holi_eve_usage': DynamicResolvedEventDate(month: 3, day: 19),
    'eid_ul_fitr_ramzan': DynamicResolvedEventDate(month: 2, day: 5),
    'good_friday': DynamicResolvedEventDate(month: 4, day: 19),
    'akshaya_tritiya': DynamicResolvedEventDate(month: 4, day: 27),
    'buddha_purnima': DynamicResolvedEventDate(month: 5, day: 17),
    'bakrid_eid_ul_adha': DynamicResolvedEventDate(month: 4, day: 14),
    'muharram_ashura': DynamicResolvedEventDate(month: 5, day: 15),
    'rath_yatra': DynamicResolvedEventDate(month: 7, day: 2),
    'milad_un_nabi': DynamicResolvedEventDate(month: 6, day: 22),
    'raksha_bandhan_sravana_purnima': DynamicResolvedEventDate(
      month: 8,
      day: 15,
    ),
    'bathukamma_starting_day': DynamicResolvedEventDate(month: 9, day: 27),
    'saddula_bathukamma_maha_saptami': DynamicResolvedEventDate(
      month: 10,
      day: 5,
    ),
    'naraka_chaturdasi': DynamicResolvedEventDate(month: 10, day: 25),
    'bhai_dooj': DynamicResolvedEventDate(month: 10, day: 28),
    'chhath_puja': DynamicResolvedEventDate(month: 10, day: 31),
  },
  2031: <String, DynamicResolvedEventDate>{
    'makara_sankranti': DynamicResolvedEventDate(month: 1, day: 14),
    'ratha_saptami': DynamicResolvedEventDate(month: 1, day: 29),
    'maha_shivaratri': DynamicResolvedEventDate(month: 2, day: 20),
    'holi': DynamicResolvedEventDate(month: 3, day: 9),
    'ugadi': DynamicResolvedEventDate(month: 3, day: 24),
    'sri_rama_navami': DynamicResolvedEventDate(month: 4, day: 1),
    'hanuman_jayanthi': DynamicResolvedEventDate(month: 4, day: 7),
    'narasimha_jayanthi': DynamicResolvedEventDate(month: 4, day: 25),
    'bonalu': DynamicResolvedEventDate(month: 6, day: 29, durationDays: 35),
    'varalakshmi_vratham': DynamicResolvedEventDate(month: 8, day: 1),
    'krishna_janmashtami': DynamicResolvedEventDate(month: 8, day: 10),
    'vinayaka_chavithi': DynamicResolvedEventDate(month: 9, day: 20),
    'bathukamma': DynamicResolvedEventDate(
      month: 10,
      day: 17,
      endMonth: 10,
      endDay: 25,
      durationDays: 9,
    ),
    'dasara_vijayadashami': DynamicResolvedEventDate(month: 10, day: 25),
    'deepavali': DynamicResolvedEventDate(month: 11, day: 14),
    'karthika_pournami_karthika_deepam': DynamicResolvedEventDate(
      month: 11,
      day: 29,
    ),
    'vaikuntha_ekadashi': DynamicResolvedEventDate(month: 12, day: 7),
    'sammakka_saralamma_jatara_medaram_jatara': DynamicResolvedEventDate(
      month: 1,
      day: 31,
      durationDays: 4,
    ),
    'nagoba_jatara': DynamicResolvedEventDate(
      month: 1,
      day: 17,
      durationDays: 5,
    ),
    'guru_nanak_jayanti': DynamicResolvedEventDate(month: 11, day: 29),
    'tyagaraja_aradhana': DynamicResolvedEventDate(month: 1, day: 16),
    'basava_jayanti': DynamicResolvedEventDate(month: 4, day: 16),
    'mahavir_jayanti': DynamicResolvedEventDate(month: 4, day: 4),
    'kanaka_durga_temple_dasara': DynamicResolvedEventDate(
      month: 10,
      day: 17,
      endMonth: 10,
      endDay: 25,
      durationDays: 9,
    ),
    'tirumala_brahmotsavam': DynamicResolvedEventDate(
      month: 10,
      day: 16,
      durationDays: 9,
    ),
    'simhachalam_chandanotsavam': DynamicResolvedEventDate(month: 4, day: 16),
    'srisailam_maha_shivaratri_brahmotsavam': DynamicResolvedEventDate(
      month: 2,
      day: 11,
      endMonth: 2,
      endDay: 21,
      durationDays: 11,
    ),
    'yadadri_brahmotsavam': DynamicResolvedEventDate(
      month: 3,
      day: 4,
      durationDays: 11,
    ),
    'bhadrachalam_sri_rama_kalyanam': DynamicResolvedEventDate(
      month: 4,
      day: 1,
    ),
    'peerla_panduga_usage': DynamicResolvedEventDate(month: 5, day: 4),
    'sri_ramanavami_sita_rama_kalyanam_usage': DynamicResolvedEventDate(
      month: 4,
      day: 1,
    ),
    'anjaneya_swamy_jayanti_usage': DynamicResolvedEventDate(month: 4, day: 7),
    'sri_narasimha_jayanti_usage': DynamicResolvedEventDate(month: 4, day: 25),
    'devotional_karthika_masam_start_usage': DynamicResolvedEventDate(
      month: 11,
      day: 16,
    ),
    'holika_dahan_holi_eve_usage': DynamicResolvedEventDate(month: 3, day: 8),
    'eid_ul_fitr_ramzan': DynamicResolvedEventDate(month: 1, day: 25),
    'good_friday': DynamicResolvedEventDate(month: 4, day: 11),
    'akshaya_tritiya': DynamicResolvedEventDate(month: 4, day: 16),
    'buddha_purnima': DynamicResolvedEventDate(month: 5, day: 7),
    'bakrid_eid_ul_adha': DynamicResolvedEventDate(month: 4, day: 4),
    'muharram_ashura': DynamicResolvedEventDate(month: 5, day: 4),
    'rath_yatra': DynamicResolvedEventDate(month: 6, day: 21),
    'milad_un_nabi': DynamicResolvedEventDate(month: 7, day: 2),
    'raksha_bandhan_sravana_purnima': DynamicResolvedEventDate(
      month: 8,
      day: 2,
    ),
    'bathukamma_starting_day': DynamicResolvedEventDate(month: 10, day: 17),
    'saddula_bathukamma_maha_saptami': DynamicResolvedEventDate(
      month: 10,
      day: 25,
    ),
    'naraka_chaturdasi': DynamicResolvedEventDate(month: 11, day: 13),
    'bhai_dooj': DynamicResolvedEventDate(month: 11, day: 16),
    'chhath_puja': DynamicResolvedEventDate(month: 11, day: 19),
  },
  2032: <String, DynamicResolvedEventDate>{
    'makara_sankranti': DynamicResolvedEventDate(month: 1, day: 15),
    'ratha_saptami': DynamicResolvedEventDate(month: 2, day: 17),
    'maha_shivaratri': DynamicResolvedEventDate(month: 3, day: 10),
    'holi': DynamicResolvedEventDate(month: 3, day: 27),
    'ugadi': DynamicResolvedEventDate(month: 4, day: 11),
    'sri_rama_navami': DynamicResolvedEventDate(month: 4, day: 19),
    'hanuman_jayanthi': DynamicResolvedEventDate(month: 4, day: 25),
    'narasimha_jayanthi': DynamicResolvedEventDate(month: 5, day: 14),
    'bonalu': DynamicResolvedEventDate(month: 7, day: 18, durationDays: 28),
    'varalakshmi_vratham': DynamicResolvedEventDate(month: 8, day: 20),
    'krishna_janmashtami': DynamicResolvedEventDate(month: 8, day: 28),
    'vinayaka_chavithi': DynamicResolvedEventDate(month: 9, day: 8),
    'bathukamma': DynamicResolvedEventDate(
      month: 10,
      day: 5,
      endMonth: 10,
      endDay: 13,
      durationDays: 9,
    ),
    'dasara_vijayadashami': DynamicResolvedEventDate(month: 10, day: 14),
    'deepavali': DynamicResolvedEventDate(month: 11, day: 2),
    'karthika_pournami_karthika_deepam': DynamicResolvedEventDate(
      month: 11,
      day: 18,
    ),
    'vaikuntha_ekadashi': DynamicResolvedEventDate(month: 12, day: 26),
    'sammakka_saralamma_jatara_medaram_jatara': DynamicResolvedEventDate(
      month: 2,
      day: 19,
      durationDays: 4,
    ),
    'nagoba_jatara': DynamicResolvedEventDate(
      month: 2,
      day: 5,
      durationDays: 5,
    ),
    'guru_nanak_jayanti': DynamicResolvedEventDate(month: 11, day: 18),
    'tyagaraja_aradhana': DynamicResolvedEventDate(month: 2, day: 4),
    'basava_jayanti': DynamicResolvedEventDate(month: 5, day: 4),
    'mahavir_jayanti': DynamicResolvedEventDate(month: 4, day: 23),
    'kanaka_durga_temple_dasara': DynamicResolvedEventDate(
      month: 10,
      day: 5,
      endMonth: 10,
      endDay: 14,
      durationDays: 10,
    ),
    'tirumala_brahmotsavam': DynamicResolvedEventDate(
      month: 10,
      day: 4,
      durationDays: 9,
    ),
    'simhachalam_chandanotsavam': DynamicResolvedEventDate(month: 5, day: 4),
    'srisailam_maha_shivaratri_brahmotsavam': DynamicResolvedEventDate(
      month: 3,
      day: 1,
      endMonth: 3,
      endDay: 11,
      durationDays: 11,
    ),
    'yadadri_brahmotsavam': DynamicResolvedEventDate(
      month: 3,
      day: 22,
      durationDays: 11,
    ),
    'bhadrachalam_sri_rama_kalyanam': DynamicResolvedEventDate(
      month: 4,
      day: 19,
    ),
    'peerla_panduga_usage': DynamicResolvedEventDate(month: 4, day: 23),
    'sri_ramanavami_sita_rama_kalyanam_usage': DynamicResolvedEventDate(
      month: 4,
      day: 19,
    ),
    'anjaneya_swamy_jayanti_usage': DynamicResolvedEventDate(month: 4, day: 25),
    'sri_narasimha_jayanti_usage': DynamicResolvedEventDate(month: 5, day: 14),
    'devotional_karthika_masam_start_usage': DynamicResolvedEventDate(
      month: 11,
      day: 4,
    ),
    'holika_dahan_holi_eve_usage': DynamicResolvedEventDate(month: 3, day: 26),
    'eid_ul_fitr_ramzan': DynamicResolvedEventDate(month: 1, day: 14),
    'good_friday': DynamicResolvedEventDate(month: 3, day: 26),
    'akshaya_tritiya': DynamicResolvedEventDate(month: 5, day: 4),
    'buddha_purnima': DynamicResolvedEventDate(month: 5, day: 26),
    'bakrid_eid_ul_adha': DynamicResolvedEventDate(month: 3, day: 22),
    'muharram_ashura': DynamicResolvedEventDate(month: 4, day: 23),
    'rath_yatra': DynamicResolvedEventDate(month: 7, day: 9),
    'milad_un_nabi': DynamicResolvedEventDate(month: 6, day: 11),
    'raksha_bandhan_sravana_purnima': DynamicResolvedEventDate(
      month: 8,
      day: 20,
    ),
    'bathukamma_starting_day': DynamicResolvedEventDate(month: 10, day: 5),
    'saddula_bathukamma_maha_saptami': DynamicResolvedEventDate(
      month: 10,
      day: 13,
    ),
    'naraka_chaturdasi': DynamicResolvedEventDate(month: 11, day: 1),
    'bhai_dooj': DynamicResolvedEventDate(month: 11, day: 4),
    'chhath_puja': DynamicResolvedEventDate(month: 11, day: 9),
  },
  2033: <String, DynamicResolvedEventDate>{
    'makara_sankranti': DynamicResolvedEventDate(month: 1, day: 14),
    'ratha_saptami': DynamicResolvedEventDate(month: 2, day: 6),
    'maha_shivaratri': DynamicResolvedEventDate(month: 2, day: 27),
    'holi': DynamicResolvedEventDate(month: 3, day: 16),
    'ugadi': DynamicResolvedEventDate(month: 3, day: 31),
    'sri_rama_navami': DynamicResolvedEventDate(month: 4, day: 8),
    'hanuman_jayanthi': DynamicResolvedEventDate(month: 4, day: 14),
    'narasimha_jayanthi': DynamicResolvedEventDate(month: 5, day: 3),
    'bonalu': DynamicResolvedEventDate(month: 7, day: 10, durationDays: 28),
    'varalakshmi_vratham': DynamicResolvedEventDate(month: 8, day: 5),
    'krishna_janmashtami': DynamicResolvedEventDate(month: 8, day: 17),
    'vinayaka_chavithi': DynamicResolvedEventDate(month: 8, day: 28),
    'bathukamma': DynamicResolvedEventDate(
      month: 9,
      day: 24,
      endMonth: 10,
      endDay: 2,
      durationDays: 9,
    ),
    'dasara_vijayadashami': DynamicResolvedEventDate(month: 10, day: 3),
    'deepavali': DynamicResolvedEventDate(month: 10, day: 22),
    'karthika_pournami_karthika_deepam': DynamicResolvedEventDate(
      month: 11,
      day: 7,
    ),
    'vaikuntha_ekadashi': DynamicResolvedEventDate(month: 12, day: 15),
    'sammakka_saralamma_jatara_medaram_jatara': DynamicResolvedEventDate(
      month: 2,
      day: 8,
      durationDays: 4,
    ),
    'nagoba_jatara': DynamicResolvedEventDate(
      month: 1,
      day: 25,
      durationDays: 5,
    ),
    'guru_nanak_jayanti': DynamicResolvedEventDate(month: 11, day: 7),
    'tyagaraja_aradhana': DynamicResolvedEventDate(month: 1, day: 24),
    'basava_jayanti': DynamicResolvedEventDate(month: 4, day: 24),
    'mahavir_jayanti': DynamicResolvedEventDate(month: 4, day: 12),
    'kanaka_durga_temple_dasara': DynamicResolvedEventDate(
      month: 9,
      day: 24,
      endMonth: 10,
      endDay: 3,
      durationDays: 10,
    ),
    'tirumala_brahmotsavam': DynamicResolvedEventDate(
      month: 9,
      day: 23,
      durationDays: 9,
    ),
    'simhachalam_chandanotsavam': DynamicResolvedEventDate(month: 4, day: 24),
    'srisailam_maha_shivaratri_brahmotsavam': DynamicResolvedEventDate(
      month: 2,
      day: 18,
      endMonth: 2,
      endDay: 28,
      durationDays: 11,
    ),
    'yadadri_brahmotsavam': DynamicResolvedEventDate(
      month: 3,
      day: 11,
      durationDays: 11,
    ),
    'bhadrachalam_sri_rama_kalyanam': DynamicResolvedEventDate(
      month: 4,
      day: 8,
    ),
    'peerla_panduga_usage': DynamicResolvedEventDate(month: 4, day: 12),
    'sri_ramanavami_sita_rama_kalyanam_usage': DynamicResolvedEventDate(
      month: 4,
      day: 8,
    ),
    'anjaneya_swamy_jayanti_usage': DynamicResolvedEventDate(month: 4, day: 14),
    'sri_narasimha_jayanti_usage': DynamicResolvedEventDate(month: 5, day: 3),
    'devotional_karthika_masam_start_usage': DynamicResolvedEventDate(
      month: 10,
      day: 24,
    ),
    'holika_dahan_holi_eve_usage': DynamicResolvedEventDate(month: 3, day: 15),
    'eid_ul_fitr_ramzan': DynamicResolvedEventDate(month: 1, day: 3),
    'good_friday': DynamicResolvedEventDate(month: 4, day: 15),
    'akshaya_tritiya': DynamicResolvedEventDate(month: 4, day: 24),
    'buddha_purnima': DynamicResolvedEventDate(month: 5, day: 15),
    'bakrid_eid_ul_adha': DynamicResolvedEventDate(month: 3, day: 11),
    'muharram_ashura': DynamicResolvedEventDate(month: 4, day: 12),
    'rath_yatra': DynamicResolvedEventDate(month: 6, day: 29),
    'milad_un_nabi': DynamicResolvedEventDate(month: 5, day: 31),
    'raksha_bandhan_sravana_purnima': DynamicResolvedEventDate(
      month: 8,
      day: 10,
    ),
    'bathukamma_starting_day': DynamicResolvedEventDate(month: 9, day: 24),
    'saddula_bathukamma_maha_saptami': DynamicResolvedEventDate(
      month: 10,
      day: 2,
    ),
    'naraka_chaturdasi': DynamicResolvedEventDate(month: 10, day: 21),
    'bhai_dooj': DynamicResolvedEventDate(month: 10, day: 25),
    'chhath_puja': DynamicResolvedEventDate(month: 10, day: 28),
  },
  2034: <String, DynamicResolvedEventDate>{
    'makara_sankranti': DynamicResolvedEventDate(month: 1, day: 14),
    'ratha_saptami': DynamicResolvedEventDate(month: 1, day: 27),
    'maha_shivaratri': DynamicResolvedEventDate(month: 2, day: 17),
    'holi': DynamicResolvedEventDate(month: 3, day: 5),
    'ugadi': DynamicResolvedEventDate(month: 3, day: 20),
    'sri_rama_navami': DynamicResolvedEventDate(month: 3, day: 28),
    'hanuman_jayanthi': DynamicResolvedEventDate(month: 4, day: 3),
    'narasimha_jayanthi': DynamicResolvedEventDate(month: 4, day: 22),
    'bonalu': DynamicResolvedEventDate(month: 7, day: 2, durationDays: 28),
    'varalakshmi_vratham': DynamicResolvedEventDate(month: 8, day: 29),
    'krishna_janmashtami': DynamicResolvedEventDate(month: 9, day: 6),
    'vinayaka_chavithi': DynamicResolvedEventDate(month: 9, day: 16),
    'bathukamma': DynamicResolvedEventDate(
      month: 10,
      day: 14,
      endMonth: 10,
      endDay: 22,
      durationDays: 9,
    ),
    'dasara_vijayadashami': DynamicResolvedEventDate(month: 10, day: 22),
    'deepavali': DynamicResolvedEventDate(month: 11, day: 10),
    'karthika_pournami_karthika_deepam': DynamicResolvedEventDate(
      month: 11,
      day: 26,
    ),
    'vaikuntha_ekadashi': DynamicResolvedEventDate(month: 12, day: 4),
    'sammakka_saralamma_jatara_medaram_jatara': DynamicResolvedEventDate(
      month: 1,
      day: 29,
      durationDays: 4,
    ),
    'nagoba_jatara': DynamicResolvedEventDate(
      month: 1,
      day: 14,
      durationDays: 5,
    ),
    'guru_nanak_jayanti': DynamicResolvedEventDate(month: 11, day: 26),
    'tyagaraja_aradhana': DynamicResolvedEventDate(month: 1, day: 13),
    'basava_jayanti': DynamicResolvedEventDate(month: 4, day: 13),
    'mahavir_jayanti': DynamicResolvedEventDate(month: 4, day: 1),
    'kanaka_durga_temple_dasara': DynamicResolvedEventDate(
      month: 10,
      day: 14,
      endMonth: 10,
      endDay: 22,
      durationDays: 9,
    ),
    'tirumala_brahmotsavam': DynamicResolvedEventDate(
      month: 10,
      day: 13,
      durationDays: 9,
    ),
    'simhachalam_chandanotsavam': DynamicResolvedEventDate(month: 4, day: 13),
    'srisailam_maha_shivaratri_brahmotsavam': DynamicResolvedEventDate(
      month: 2,
      day: 8,
      endMonth: 2,
      endDay: 18,
      durationDays: 11,
    ),
    'yadadri_brahmotsavam': DynamicResolvedEventDate(
      month: 3,
      day: 1,
      durationDays: 11,
    ),
    'bhadrachalam_sri_rama_kalyanam': DynamicResolvedEventDate(
      month: 3,
      day: 28,
    ),
    'peerla_panduga_usage': DynamicResolvedEventDate(month: 4, day: 1),
    'sri_ramanavami_sita_rama_kalyanam_usage': DynamicResolvedEventDate(
      month: 3,
      day: 28,
    ),
    'anjaneya_swamy_jayanti_usage': DynamicResolvedEventDate(month: 4, day: 3),
    'sri_narasimha_jayanti_usage': DynamicResolvedEventDate(month: 4, day: 22),
    'devotional_karthika_masam_start_usage': DynamicResolvedEventDate(
      month: 11,
      day: 12,
    ),
    'holika_dahan_holi_eve_usage': DynamicResolvedEventDate(month: 3, day: 4),
    'eid_ul_fitr_ramzan': DynamicResolvedEventDate(month: 12, day: 23),
    'good_friday': DynamicResolvedEventDate(month: 4, day: 7),
    'akshaya_tritiya': DynamicResolvedEventDate(month: 4, day: 13),
    'buddha_purnima': DynamicResolvedEventDate(month: 5, day: 4),
    'bakrid_eid_ul_adha': DynamicResolvedEventDate(month: 2, day: 28),
    'muharram_ashura': DynamicResolvedEventDate(month: 4, day: 1),
    'rath_yatra': DynamicResolvedEventDate(month: 7, day: 17),
    'milad_un_nabi': DynamicResolvedEventDate(month: 5, day: 20),
    'raksha_bandhan_sravana_purnima': DynamicResolvedEventDate(
      month: 8,
      day: 29,
    ),
    'bathukamma_starting_day': DynamicResolvedEventDate(month: 10, day: 14),
    'saddula_bathukamma_maha_saptami': DynamicResolvedEventDate(
      month: 10,
      day: 22,
    ),
    'naraka_chaturdasi': DynamicResolvedEventDate(month: 11, day: 9),
    'bhai_dooj': DynamicResolvedEventDate(month: 11, day: 12),
    'chhath_puja': DynamicResolvedEventDate(month: 11, day: 17),
  },
  2035: <String, DynamicResolvedEventDate>{
    'makara_sankranti': DynamicResolvedEventDate(month: 1, day: 15),
    'ratha_saptami': DynamicResolvedEventDate(month: 2, day: 14),
    'maha_shivaratri': DynamicResolvedEventDate(month: 3, day: 8),
    'holi': DynamicResolvedEventDate(month: 3, day: 24),
    'ugadi': DynamicResolvedEventDate(month: 4, day: 8),
    'sri_rama_navami': DynamicResolvedEventDate(month: 4, day: 16),
    'hanuman_jayanthi': DynamicResolvedEventDate(month: 4, day: 22),
    'narasimha_jayanthi': DynamicResolvedEventDate(month: 5, day: 11),
    'bonalu': DynamicResolvedEventDate(month: 7, day: 22, durationDays: 28),
    'varalakshmi_vratham': DynamicResolvedEventDate(month: 8, day: 17),
    'krishna_janmashtami': DynamicResolvedEventDate(month: 8, day: 27),
    'vinayaka_chavithi': DynamicResolvedEventDate(month: 9, day: 5),
    'bathukamma': DynamicResolvedEventDate(
      month: 10,
      day: 3,
      endMonth: 10,
      endDay: 11,
      durationDays: 9,
    ),
    'dasara_vijayadashami': DynamicResolvedEventDate(month: 10, day: 12),
    'deepavali': DynamicResolvedEventDate(month: 10, day: 30),
    'karthika_pournami_karthika_deepam': DynamicResolvedEventDate(
      month: 11,
      day: 15,
    ),
    'vaikuntha_ekadashi': DynamicResolvedEventDate(month: 12, day: 23),
    'sammakka_saralamma_jatara_medaram_jatara': DynamicResolvedEventDate(
      month: 2,
      day: 16,
      durationDays: 4,
    ),
    'nagoba_jatara': DynamicResolvedEventDate(
      month: 2,
      day: 3,
      durationDays: 5,
    ),
    'guru_nanak_jayanti': DynamicResolvedEventDate(month: 11, day: 15),
    'tyagaraja_aradhana': DynamicResolvedEventDate(month: 2, day: 2),
    'basava_jayanti': DynamicResolvedEventDate(month: 5, day: 2),
    'mahavir_jayanti': DynamicResolvedEventDate(month: 4, day: 20),
    'kanaka_durga_temple_dasara': DynamicResolvedEventDate(
      month: 10,
      day: 3,
      endMonth: 10,
      endDay: 12,
      durationDays: 10,
    ),
    'tirumala_brahmotsavam': DynamicResolvedEventDate(
      month: 10,
      day: 2,
      durationDays: 9,
    ),
    'simhachalam_chandanotsavam': DynamicResolvedEventDate(month: 5, day: 2),
    'srisailam_maha_shivaratri_brahmotsavam': DynamicResolvedEventDate(
      month: 2,
      day: 27,
      endMonth: 3,
      endDay: 9,
      durationDays: 11,
    ),
    'yadadri_brahmotsavam': DynamicResolvedEventDate(
      month: 3,
      day: 20,
      durationDays: 11,
    ),
    'bhadrachalam_sri_rama_kalyanam': DynamicResolvedEventDate(
      month: 4,
      day: 16,
    ),
    'peerla_panduga_usage': DynamicResolvedEventDate(month: 3, day: 21),
    'sri_ramanavami_sita_rama_kalyanam_usage': DynamicResolvedEventDate(
      month: 4,
      day: 16,
    ),
    'anjaneya_swamy_jayanti_usage': DynamicResolvedEventDate(month: 4, day: 22),
    'sri_narasimha_jayanti_usage': DynamicResolvedEventDate(month: 5, day: 11),
    'devotional_karthika_masam_start_usage': DynamicResolvedEventDate(
      month: 11,
      day: 1,
    ),
    'holika_dahan_holi_eve_usage': DynamicResolvedEventDate(month: 3, day: 23),
    'eid_ul_fitr_ramzan': DynamicResolvedEventDate(month: 12, day: 12),
    'good_friday': DynamicResolvedEventDate(month: 3, day: 23),
    'akshaya_tritiya': DynamicResolvedEventDate(month: 5, day: 2),
    'buddha_purnima': DynamicResolvedEventDate(month: 5, day: 23),
    'bakrid_eid_ul_adha': DynamicResolvedEventDate(month: 2, day: 17),
    'muharram_ashura': DynamicResolvedEventDate(month: 3, day: 21),
    'rath_yatra': DynamicResolvedEventDate(month: 7, day: 6),
    'milad_un_nabi': DynamicResolvedEventDate(month: 5, day: 10),
    'raksha_bandhan_sravana_purnima': DynamicResolvedEventDate(
      month: 8,
      day: 18,
    ),
    'bathukamma_starting_day': DynamicResolvedEventDate(month: 10, day: 3),
    'saddula_bathukamma_maha_saptami': DynamicResolvedEventDate(
      month: 10,
      day: 11,
    ),
    'naraka_chaturdasi': DynamicResolvedEventDate(month: 10, day: 29),
    'bhai_dooj': DynamicResolvedEventDate(month: 11, day: 1),
    'chhath_puja': DynamicResolvedEventDate(month: 11, day: 6),
  },
  2036: <String, DynamicResolvedEventDate>{
    'makara_sankranti': DynamicResolvedEventDate(month: 1, day: 15),
    'ratha_saptami': DynamicResolvedEventDate(month: 2, day: 3),
    'maha_shivaratri': DynamicResolvedEventDate(month: 2, day: 25),
    'holi': DynamicResolvedEventDate(month: 3, day: 12),
    'ugadi': DynamicResolvedEventDate(month: 3, day: 28),
    'sri_rama_navami': DynamicResolvedEventDate(month: 4, day: 5),
    'hanuman_jayanthi': DynamicResolvedEventDate(month: 4, day: 11),
    'narasimha_jayanthi': DynamicResolvedEventDate(month: 4, day: 30),
    'bonalu': DynamicResolvedEventDate(month: 7, day: 13, durationDays: 28),
    'varalakshmi_vratham': DynamicResolvedEventDate(month: 8, day: 8),
    'krishna_janmashtami': DynamicResolvedEventDate(month: 8, day: 15),
    'vinayaka_chavithi': DynamicResolvedEventDate(month: 8, day: 25),
    'bathukamma': DynamicResolvedEventDate(
      month: 9,
      day: 21,
      endMonth: 9,
      endDay: 29,
      durationDays: 9,
    ),
    'dasara_vijayadashami': DynamicResolvedEventDate(month: 9, day: 30),
    'deepavali': DynamicResolvedEventDate(month: 10, day: 19),
    'karthika_pournami_karthika_deepam': DynamicResolvedEventDate(
      month: 11,
      day: 4,
    ),
    'vaikuntha_ekadashi': DynamicResolvedEventDate(month: 12, day: 13),
    'sammakka_saralamma_jatara_medaram_jatara': DynamicResolvedEventDate(
      month: 2,
      day: 5,
      durationDays: 4,
    ),
    'nagoba_jatara': DynamicResolvedEventDate(
      month: 1,
      day: 23,
      durationDays: 5,
    ),
    'guru_nanak_jayanti': DynamicResolvedEventDate(month: 11, day: 4),
    'tyagaraja_aradhana': DynamicResolvedEventDate(month: 1, day: 22),
    'basava_jayanti': DynamicResolvedEventDate(month: 4, day: 21),
    'mahavir_jayanti': DynamicResolvedEventDate(month: 4, day: 9),
    'kanaka_durga_temple_dasara': DynamicResolvedEventDate(
      month: 9,
      day: 21,
      endMonth: 9,
      endDay: 30,
      durationDays: 10,
    ),
    'tirumala_brahmotsavam': DynamicResolvedEventDate(
      month: 9,
      day: 20,
      durationDays: 9,
    ),
    'simhachalam_chandanotsavam': DynamicResolvedEventDate(month: 4, day: 21),
    'srisailam_maha_shivaratri_brahmotsavam': DynamicResolvedEventDate(
      month: 2,
      day: 16,
      endMonth: 2,
      endDay: 26,
      durationDays: 11,
    ),
    'yadadri_brahmotsavam': DynamicResolvedEventDate(
      month: 3,
      day: 9,
      durationDays: 11,
    ),
    'bhadrachalam_sri_rama_kalyanam': DynamicResolvedEventDate(
      month: 4,
      day: 5,
    ),
    'peerla_panduga_usage': DynamicResolvedEventDate(month: 3, day: 9),
    'sri_ramanavami_sita_rama_kalyanam_usage': DynamicResolvedEventDate(
      month: 4,
      day: 5,
    ),
    'anjaneya_swamy_jayanti_usage': DynamicResolvedEventDate(month: 4, day: 11),
    'sri_narasimha_jayanti_usage': DynamicResolvedEventDate(month: 4, day: 30),
    'devotional_karthika_masam_start_usage': DynamicResolvedEventDate(
      month: 10,
      day: 21,
    ),
    'holika_dahan_holi_eve_usage': DynamicResolvedEventDate(month: 3, day: 11),
    'eid_ul_fitr_ramzan': DynamicResolvedEventDate(month: 12, day: 2),
    'good_friday': DynamicResolvedEventDate(month: 4, day: 11),
    'akshaya_tritiya': DynamicResolvedEventDate(month: 4, day: 21),
    'buddha_purnima': DynamicResolvedEventDate(month: 5, day: 12),
    'bakrid_eid_ul_adha': DynamicResolvedEventDate(month: 2, day: 8),
    'muharram_ashura': DynamicResolvedEventDate(month: 3, day: 9),
    'rath_yatra': DynamicResolvedEventDate(month: 6, day: 25),
    'milad_un_nabi': DynamicResolvedEventDate(month: 4, day: 29),
    'raksha_bandhan_sravana_purnima': DynamicResolvedEventDate(
      month: 8,
      day: 7,
    ),
    'bathukamma_starting_day': DynamicResolvedEventDate(month: 9, day: 21),
    'saddula_bathukamma_maha_saptami': DynamicResolvedEventDate(
      month: 9,
      day: 29,
    ),
    'naraka_chaturdasi': DynamicResolvedEventDate(month: 10, day: 18),
    'bhai_dooj': DynamicResolvedEventDate(month: 10, day: 21),
    'chhath_puja': DynamicResolvedEventDate(month: 10, day: 26),
  },
};

final Map<int, Map<String, DynamicResolvedEventDate>>
_runtimeResolvedLunarEventDates =
    <int, Map<String, DynamicResolvedEventDate>>{};

Map<String, DynamicResolvedEventDate> resolvedLunarEventDatesForYear(int year) {
  return _runtimeResolvedLunarEventDates[year] ??
      kResolvedLunarEventDates[year] ??
      const <String, DynamicResolvedEventDate>{};
}

class DynamicLunarEventDateStore {
  const DynamicLunarEventDateStore({FirebaseFirestore? firestore})
    : _firestore = firestore;

  final FirebaseFirestore? _firestore;

  FirebaseFirestore get firestore => _firestore ?? FirebaseFirestore.instance;

  Future<void> preloadYear(int year) async {
    if (_runtimeResolvedLunarEventDates.containsKey(year) ||
        kResolvedLunarEventDates.containsKey(year)) {
      return;
    }

    try {
      final snapshot = await firestore
          .collection('dynamic_lunar_event_dates')
          .doc('$year')
          .get();
      if (!snapshot.exists) {
        return;
      }

      final data = snapshot.data();
      if (data == null) {
        return;
      }

      final resolved = _parseYearMap(data);
      if (resolved.isNotEmpty) {
        _runtimeResolvedLunarEventDates[year] = resolved;
      }
    } catch (_) {
      // Keep local fallback when remote year data is unavailable.
    }
  }

  Future<void> preloadYears(Iterable<int> years) async {
    for (final year in years.toSet()) {
      await preloadYear(year);
    }
  }

  Map<String, DynamicResolvedEventDate> _parseYearMap(
    Map<String, dynamic> data,
  ) {
    final rawEvents = data['events'];
    final source = rawEvents is Map<String, dynamic> ? rawEvents : data;
    final output = <String, DynamicResolvedEventDate>{};

    for (final entry in source.entries) {
      final value = entry.value;
      if (value is! Map<String, dynamic>) {
        continue;
      }
      final month = _asInt(value['month']);
      final day = _asInt(value['day']);
      if (month == null || day == null) {
        continue;
      }
      output[entry.key] = DynamicResolvedEventDate(
        month: month,
        day: day,
        endMonth: _asInt(value['endMonth']),
        endDay: _asInt(value['endDay']),
        durationDays: _asInt(value['durationDays']) ?? 1,
      );
    }

    return output;
  }

  int? _asInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }
}
