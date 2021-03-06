; Princess Engine
; Copyright (C) 2016-2018 NovaSquirrel
;
; This program is free software: you can redistribute it and/or
; modify it under the terms of the GNU General Public License as
; published by the Free Software Foundation; either version 3 of the
; License, or (at your option) any later version.
;
; This program is distributed in the hope that it will be useful, but
; WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
; General Public License for more details.
;
; You should have received a copy of the GNU General Public License
; along with this program.  If not, see <http://www.gnu.org/licenses/>.
;

.proc CharacterNameData
None:     .byt 0
Nova:     .byt "Nova",0
Kee:      .byt "Kee",0
Sherwin:  .byt "Sherwin",0
Korey:    .byt "Korey",0
Remy:     .byt "Remy D.",0
Eclipse:  .byt "Eclipse",0
MolSno:   .byt "MolSno",0
S_Team:   .byt "S.Team",0
Smiloid:  .byt "Smiloid",0
Ike:      .byt "Ike",0
Raoul:    .byt "Raoul",0
Jafguar:  .byt "Jafguar",0
Lia:      .byt "Lia",0
Iti:      .byt "Itimar",0
Bill:     .byt "William",0
John:     .byt "John",0
.endproc

.proc CharacterInfoTable
  ; Name offset, and then three colors
  .byt CharacterNameData::None - CharacterNameData,    $00, $00, $00 ; nothing
  .byt CharacterNameData::None - CharacterNameData,    $17, $27, $37 ; sign
  .byt CharacterNameData::Nova - CharacterNameData,    $12, $2a, $30
  .byt CharacterNameData::Kee - CharacterNameData,     $07, $00, $27
  .byt CharacterNameData::Sherwin - CharacterNameData, $17, $27, $37
  .byt CharacterNameData::None - CharacterNameData,    $0f, $27, $2c ; forum
  .byt CharacterNameData::Korey - CharacterNameData,   $12, $21, $31
  .byt CharacterNameData::Remy - CharacterNameData,    $0f, $2a, $30
  .byt CharacterNameData::Eclipse - CharacterNameData, $15, $25, $38
  .byt CharacterNameData::MolSno - CharacterNameData,  $0f, $16, $30
  .byt CharacterNameData::S_Team - CharacterNameData,  $0f, $16, $30
  .byt CharacterNameData::Smiloid - CharacterNameData, $0f, $16, $30
  .byt CharacterNameData::Ike - CharacterNameData,     $17, $26, $30
  .byt CharacterNameData::Raoul - CharacterNameData,   $0f, $10, $30
  .byt CharacterNameData::Jafguar - CharacterNameData, $17, $27, $38
  .byt CharacterNameData::Lia - CharacterNameData,     $00, $10, $28
  .byt CharacterNameData::Iti - CharacterNameData,     $0f, $21, $30
  .byt CharacterNameData::John - CharacterNameData,    $0f, $21, $30
  .byt CharacterNameData::None - CharacterNameData,    $00, $00, $00
  .byt CharacterNameData::Bill - CharacterNameData,    $0f, $16, $30
  .byt CharacterNameData::None - CharacterNameData,    $00, $00, $00
  .byt CharacterNameData::None - CharacterNameData,    $00, $00, $00
  .byt CharacterNameData::Nova - CharacterNameData,    $12, $2a, $30
  .byt CharacterNameData::Nova - CharacterNameData,    $12, $2a, $30
  .byt CharacterNameData::Nova - CharacterNameData,    $12, $2a, $30
  .byt CharacterNameData::Nova - CharacterNameData,    $12, $2a, $30
  .byt CharacterNameData::Nova - CharacterNameData,    $12, $2a, $30
.endproc

.proc SceneInfoTable
  FLIP = 128
  ; [hppccccc]*4
  ;  |||+++++- character graphic
  ;  |++------ position (0-3)
  ;  +-------- horizontally flipped?
  .byt 0, 0, 0, 0
  .byt CHAR::NOVA|(1<<5), CHAR::SIGN|(2<<5), 0, 0
  .byt CHAR::FORUM|(0<<5), CHAR::FORUM|(1<<5), CHAR::FORUM|(2<<5), CHAR::FORUM|(3<<5)
  .byt CHAR::NOVA|(1<<5), CHAR::KEE|(2<<5)|FLIP, 0, 0
  .byt CHAR::NOVA|(1<<5), CHAR::KEE|(2<<5), CHAR::SIGN|(3<<5)|FLIP, 0
  .byt CHAR::NOVA|(1<<5), CHAR::SIGN|(2<<5)|FLIP, CHAR::KEE|(0<<5), 0
  .byt CHAR::S_TEAM|(1<<5), CHAR::S_TEAM|(2<<5)|FLIP, 0, 0
  .byt CHAR::SHERWIN|(1<<5), CHAR::S_TEAM|(0<<5), CHAR::S_TEAM|(2<<5)|FLIP, 0
  .byt CHAR::SHERWIN|(1<<5), 0, 0, 0
  .byt CHAR::S_TEAM|(1<<5), CHAR::S_TEAM|(2<<5), CHAR::BILL|(3<<5)|FLIP, 0
  .byt CHAR::NOVA|(1<<5), CHAR::LIA|(0<<5), CHAR::ECLIPSE|(2<<5)|FLIP, 0
  .byt CHAR::NOVA|(1<<5), CHAR::MOLSNO|(2<<5)|FLIP, 0, 0
  .byt CHAR::NOVA|(1<<5), CHAR::REMY|(2<<5)|FLIP, 0, 0
  .byt CHAR::NOVA|(1<<5), CHAR::REMY|(2<<5)|FLIP, CHAR::JAFGUAR|(3<<5)|FLIP, 0
  .byt CHAR::NOVA|(1<<5), CHAR::RAOUL|(2<<5)|FLIP, 0, 0
  .byt CHAR::NOVA|(1<<5), 0, 0, 0
  .byt CHAR::NOVA|(1<<5), CHAR::S_TEAM|(0<<5), CHAR::S_TEAM|(3<<5)|FLIP, 0
  .byt CHAR::NOVA|(1<<5), CHAR::KOREY|(2<<5)|FLIP, 0, 0
  .byt CHAR::NOVA|(1<<5), CHAR::BILL|(2<<5), 0, 0
  .byt CHAR::NOVA|(1<<5), CHAR::SHERWIN|(2<<5)|FLIP, 0, 0
  .byt CHAR::NOVA|(1<<5), CHAR::SHERWIN|(2<<5)|FLIP, CHAR::KOREY|(3<<5)|FLIP, 0
  .byt CHAR::NOVA|(1<<5), CHAR::LIA|(2<<5)|FLIP, 0, 0
  .byt CHAR::NOVA|(1<<5), CHAR::ITI|(2<<5)|FLIP, 0, 0
  .byt CHAR::NOVA|(1<<5), CHAR::SMILOID|(2<<5)|FLIP, CHAR::S_TEAM|(3<<5)|FLIP, 0
  .byt CHAR::NOVA|(1<<5), CHAR::IKE|(2<<5)|FLIP, 0, 0
  .byt CHAR::NOVA|(1<<5), CHAR::S_TEAM|(0<<5), CHAR::S_TEAM|(2<<5)|FLIP, CHAR::IKE|(3<<5)|FLIP
  .byt CHAR::NOVA|(2<<5), CHAR::LIA|(1<<5), CHAR::SIGN|(3<<5)|FLIP, 0
  .byt CHAR::NOVA|(1<<5), CHAR::JOHN|(2<<5)|FLIP, 0, 0
.endproc

.enum SCENES
  NOTHING
  NOVA_AND_SIGN
  FORUMS
  NOVA_AND_KEE
  NOVA_KEE_SIGN
  NOVA_SIGN_KEE
  TWO_BAD_GUYS
  SHERWIN_WITH_BAD_GUYS_AS_POLICE
  SHERWIN_ALONE
  BAD_GUYS_AND_LEADER
  NOVA_AND_ECLIPSE
  NOVA_AND_MOLSNO
  NOVA_AND_REMY
  NOVA_REMY_JAFGUAR
  NOVA_AND_RAOUL
  NOVA_ALONE
  NOVA_AND_BAD_GUYS
  NOVA_AND_KOREY
  NOVA_AND_BILL
  NOVA_AND_SHERWIN
  NOVA_SHERWIN_KOREY
  NOVA_AND_LIA
  NOVA_AND_ITI
  NOVA_AND_SMILOID
  NOVA_AND_IKE
  NOVA_AND_BAD_GUYS_AND_IKE
  NOVA_LIA_SIGN
  NOVA_AND_JOHN
.endenum

FaceData:
  .incbin "../chr/faces2.chr"
