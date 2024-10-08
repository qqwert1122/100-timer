import 'package:flutter/material.dart';

// 아이콘 이름을 IconData로 변환하는 함수
IconData getIconData(String? iconName) {
  switch (iconName) {
    // 1. 추천
    case 'category_rounded':
      return Icons.category_rounded;
    case 'school_rounded':
      return Icons.school_rounded;
    case 'work_rounded':
      return Icons.work_rounded;
    case 'fitness_center_rounded':
      return Icons.fitness_center_rounded;
    case 'more_horiz_rounded':
      return Icons.more_horiz_rounded;
    case 'library':
      return Icons.local_library;
    case 'art':
      return Icons.palette;
    case 'computer':
      return Icons.computer;
    case 'edit':
      return Icons.edit;
    case 'keyboard':
      return Icons.keyboard;
    case 'library_books':
      return Icons.library_books;
    case 'language':
      return Icons.language;
    case 'science':
      return Icons.science;

    // 2. 업무와 관련된 아이콘
    case 'business':
      return Icons.business;
    case 'money':
      return Icons.attach_money;
    case 'email':
      return Icons.email;
    case 'meeting':
      return Icons.meeting_room;
    case 'analytics':
      return Icons.analytics;
    case 'assignment':
      return Icons.assignment;
    case 'person_add':
      return Icons.person_add;
    case 'chart':
      return Icons.pie_chart;
    case 'phone':
      return Icons.phone;
    case 'print':
      return Icons.print;
    case 'timeline':
      return Icons.timeline;
    case 'folder_open':
      return Icons.folder_open;
    case 'fact_check':
      return Icons.fact_check;

    // 3. 운동과 관련된 아이콘
    case 'running':
      return Icons.directions_run;
    case 'swimming':
      return Icons.pool;
    case 'soccer':
      return Icons.sports_soccer;
    case 'basketball':
      return Icons.sports_basketball;
    case 'tennis':
      return Icons.sports_tennis;
    case 'volleyball':
      return Icons.sports_volleyball;
    case 'bike':
      return Icons.directions_bike;
    case 'golf':
      return Icons.sports_golf;
    case 'mma':
      return Icons.sports_mma;
    case 'cricket':
      return Icons.sports_cricket;
    case 'esports':
      return Icons.sports_esports;

    // 4. 그외 자기계발과 관련된 아이콘
    case 'ideas':
      return Icons.lightbulb;
    case 'tools':
      return Icons.build;
    case 'healing':
      return Icons.healing;
    case 'spa':
      return Icons.spa;
    case 'park':
      return Icons.park;
    case 'gavel':
      return Icons.gavel;
    case 'hiking':
      return Icons.hiking;
    case 'group_work':
      return Icons.group;
    case 'pets':
      return Icons.pets;
    case 'cleaning':
      return Icons.cleaning_services;
    case 'security':
      return Icons.security;
    case 'volunteer':
      return Icons.volunteer_activism;
    case 'mentoring':
      return Icons.supervised_user_circle;

    // 5. 그 외 일상 관련된 아이콘
    case 'home':
      return Icons.home;
    case 'restaurant':
      return Icons.restaurant;
    case 'coffee':
      return Icons.coffee;
    case 'hospital':
      return Icons.local_hospital;
    case 'shopping':
      return Icons.shopping_cart;
    case 'movie':
      return Icons.movie;
    case 'music':
      return Icons.music_note;
    case 'flight':
      return Icons.flight;
    case 'hotel':
      return Icons.hotel;
    case 'camera':
      return Icons.camera_alt;
    case 'car':
      return Icons.directions_car;
    case 'boat':
      return Icons.directions_boat;
    case 'train':
      return Icons.train;
    case 'subway':
      return Icons.subway;
    case 'walk':
      return Icons.directions_walk;
    case 'cafe':
      return Icons.local_cafe;
    case 'tv':
      return Icons.tv;
    case 'gaming':
      return Icons.videogame_asset;
    case 'theater':
      return Icons.theater_comedy;
    case 'radio':
      return Icons.radio;
    case 'headset':
      return Icons.headset;
    case 'mic':
      return Icons.mic;
    case 'music_video':
      return Icons.music_video;
    case 'bus':
      return Icons.directions_bus;
    case 'painting':
      return Icons.brush;
    case 'map':
      return Icons.map;
    case 'photo':
      return Icons.add_a_photo;
    case 'beach':
      return Icons.beach_access;
    case 'bubble_chart':
      return Icons.bubble_chart;
    case 'wine_bar':
      return Icons.wine_bar;
    case 'weather':
      return Icons.ac_unit;
    case 'kabaddi':
      return Icons.sports_kabaddi;
    case 'village':
      return Icons.holiday_village;
    case 'architecture':
      return Icons.architecture;
    default:
      return Icons.help_outline; // 기본 아이콘
  }
}
