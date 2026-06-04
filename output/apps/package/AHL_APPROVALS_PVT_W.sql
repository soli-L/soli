
  CREATE OR REPLACE EDITIONABLE PACKAGE "APPS"."AHL_APPROVALS_PVT_W" AUTHID CURRENT_USER as
  /* $Header: AHLWAPRS.pls 120.0.12020000.2 2019/10/23 00:18:08 sracha ship $ */
  procedure rosetta_table_copy_in_p2(t out nocopy ahl_approvals_pvt.approvers_tbl, a0 JTF_NUMBER_TABLE
    , a1 JTF_NUMBER_TABLE
    , a2 JTF_NUMBER_TABLE
    , a3 JTF_VARCHAR2_TABLE_100
    , a4 JTF_NUMBER_TABLE
    , a5 JTF_NUMBER_TABLE
    , a6 JTF_VARCHAR2_TABLE_100
    , a7 JTF_DATE_TABLE
    , a8 JTF_NUMBER_TABLE
    , a9 JTF_DATE_TABLE
    , a10 JTF_NUMBER_TABLE
    , a11 JTF_NUMBER_TABLE
    , a12 JTF_VARCHAR2_TABLE_100
    , a13 JTF_VARCHAR2_TABLE_200
    , a14 JTF_VARCHAR2_TABLE_200
    , a15 JTF_VARCHAR2_TABLE_200
    , a16 JTF_VARCHAR2_TABLE_200
    , a17 JTF_VARCHAR2_TABLE_200
    , a18 JTF_VARCHAR2_TABLE_200
    , a19 JTF_VARCHAR2_TABLE_200
    , a20 JTF_VARCHAR2_TABLE_200
    , a21 JTF_VARCHAR2_TABLE_200
    , a22 JTF_VARCHAR2_TABLE_200
    , a23 JTF_VARCHAR2_TABLE_200
    , a24 JTF_VARCHAR2_TABLE_200
    , a25 JTF_VARCHAR2_TABLE_200
    , a26 JTF_VARCHAR2_TABLE_200
    , a27 JTF_VARCHAR2_TABLE_200
    , a28 JTF_VARCHAR2_TABLE_100
    );
  procedure rosetta_table_copy_out_p2(t ahl_approvals_pvt.approvers_tbl, a0 out nocopy JTF_NUMBER_TABLE
    , a1 out nocopy JTF_NUMBER_TABLE
    , a2 out nocopy JTF_NUMBER_TABLE
    , a3 out nocopy JTF_VARCHAR2_TABLE_100
    , a4 out nocopy JTF_NUMBER_TABLE
    , a5 out nocopy JTF_NUMBER_TABLE
    , a6 out nocopy JTF_VARCHAR2_TABLE_100
    , a7 out nocopy JTF_DATE_TABLE
    , a8 out nocopy JTF_NUMBER_TABLE
    , a9 out nocopy JTF_DATE_TABLE
    , a10 out nocopy JTF_NUMBER_TABLE
    , a11 out nocopy JTF_NUMBER_TABLE
    , a12 out nocopy JTF_VARCHAR2_TABLE_100
    , a13 out nocopy JTF_VARCHAR2_TABLE_200
    , a14 out nocopy JTF_VARCHAR2_TABLE_200
    , a15 out nocopy JTF_VARCHAR2_TABLE_200
    , a16 out nocopy JTF_VARCHAR2_TABLE_200
    , a17 out nocopy JTF_VARCHAR2_TABLE_200
    , a18 out nocopy JTF_VARCHAR2_TABLE_200
    , a19 out nocopy JTF_VARCHAR2_TABLE_200
    , a20 out nocopy JTF_VARCHAR2_TABLE_200
    , a21 out nocopy JTF_VARCHAR2_TABLE_200
    , a22 out nocopy JTF_VARCHAR2_TABLE_200
    , a23 out nocopy JTF_VARCHAR2_TABLE_200
    , a24 out nocopy JTF_VARCHAR2_TABLE_200
    , a25 out nocopy JTF_VARCHAR2_TABLE_200
    , a26 out nocopy JTF_VARCHAR2_TABLE_200
    , a27 out nocopy JTF_VARCHAR2_TABLE_200
    , a28 out nocopy JTF_VARCHAR2_TABLE_100
    );

  procedure process_approvals(p_api_version  NUMBER
    , p_init_msg_list  VARCHAR2
    , p_commit  VARCHAR2
    , p_validation_level  NUMBER
    , p4_a0 in out nocopy  NUMBER
    , p4_a1 in out nocopy  NUMBER
    , p4_a2 in out nocopy  VARCHAR2
    , p4_a3 in out nocopy  VARCHAR2
    , p4_a4 in out nocopy  VARCHAR2
    , p4_a5 in out nocopy  VARCHAR2
    , p4_a6 in out nocopy  VARCHAR2
    , p4_a7 in out nocopy  NUMBER
    , p4_a8 in out nocopy  VARCHAR2
    , p4_a9 in out nocopy  DATE
    , p4_a10 in out nocopy  DATE
    , p4_a11 in out nocopy  VARCHAR2
    , p4_a12 in out nocopy  VARCHAR2
    , p4_a13 in out nocopy  VARCHAR2
    , p4_a14 in out nocopy  VARCHAR2
    , p4_a15 in out nocopy  VARCHAR2
    , p4_a16 in out nocopy  VARCHAR2
    , p4_a17 in out nocopy  VARCHAR2
    , p4_a18 in out nocopy  VARCHAR2
    , p4_a19 in out nocopy  VARCHAR2
    , p4_a20 in out nocopy  VARCHAR2
    , p4_a21 in out nocopy  VARCHAR2
    , p4_a22 in out nocopy  VARCHAR2
    , p4_a23 in out nocopy  VARCHAR2
    , p4_a24 in out nocopy  VARCHAR2
    , p4_a25 in out nocopy  VARCHAR2
    , p4_a26 in out nocopy  VARCHAR2
    , p4_a27 in out nocopy  VARCHAR2
    , p4_a28 in out nocopy  VARCHAR2
    , p4_a29 in out nocopy  VARCHAR2
    , p4_a30 in out nocopy  VARCHAR2
    , p4_a31 in out nocopy  DATE
    , p4_a32 in out nocopy  NUMBER
    , p4_a33 in out nocopy  DATE
    , p4_a34 in out nocopy  NUMBER
    , p4_a35 in out nocopy  NUMBER
    , p4_a36 in out nocopy  VARCHAR2
    , p4_a37 in out nocopy  VARCHAR2
    , p4_a38 in out nocopy  VARCHAR2
    , p4_a39 in out nocopy  VARCHAR2
    , p5_a0 in out nocopy JTF_NUMBER_TABLE
    , p5_a1 in out nocopy JTF_NUMBER_TABLE
    , p5_a2 in out nocopy JTF_NUMBER_TABLE
    , p5_a3 in out nocopy JTF_VARCHAR2_TABLE_100
    , p5_a4 in out nocopy JTF_NUMBER_TABLE
    , p5_a5 in out nocopy JTF_NUMBER_TABLE
    , p5_a6 in out nocopy JTF_VARCHAR2_TABLE_100
    , p5_a7 in out nocopy JTF_DATE_TABLE
    , p5_a8 in out nocopy JTF_NUMBER_TABLE
    , p5_a9 in out nocopy JTF_DATE_TABLE
    , p5_a10 in out nocopy JTF_NUMBER_TABLE
    , p5_a11 in out nocopy JTF_NUMBER_TABLE
    , p5_a12 in out nocopy JTF_VARCHAR2_TABLE_100
    , p5_a13 in out nocopy JTF_VARCHAR2_TABLE_200
    , p5_a14 in out nocopy JTF_VARCHAR2_TABLE_200
    , p5_a15 in out nocopy JTF_VARCHAR2_TABLE_200
    , p5_a16 in out nocopy JTF_VARCHAR2_TABLE_200
    , p5_a17 in out nocopy JTF_VARCHAR2_TABLE_200
    , p5_a18 in out nocopy JTF_VARCHAR2_TABLE_200
    , p5_a19 in out nocopy JTF_VARCHAR2_TABLE_200
    , p5_a20 in out nocopy JTF_VARCHAR2_TABLE_200
    , p5_a21 in out nocopy JTF_VARCHAR2_TABLE_200
    , p5_a22 in out nocopy JTF_VARCHAR2_TABLE_200
    , p5_a23 in out nocopy JTF_VARCHAR2_TABLE_200
    , p5_a24 in out nocopy JTF_VARCHAR2_TABLE_200
    , p5_a25 in out nocopy JTF_VARCHAR2_TABLE_200
    , p5_a26 in out nocopy JTF_VARCHAR2_TABLE_200
    , p5_a27 in out nocopy JTF_VARCHAR2_TABLE_200
    , p5_a28 in out nocopy JTF_VARCHAR2_TABLE_100
    , x_return_status out nocopy  VARCHAR2
    , x_msg_count out nocopy  NUMBER
    , x_msg_data out nocopy  VARCHAR2
  );
  procedure create_approval_rules(p_api_version  NUMBER
    , p_init_msg_list  VARCHAR2
    , p_commit  VARCHAR2
    , p_validation_level  NUMBER
    , x_return_status out nocopy  VARCHAR2
    , x_msg_count out nocopy  NUMBER
    , x_msg_data out nocopy  VARCHAR2
    , p7_a0  NUMBER
    , p7_a1  NUMBER
    , p7_a2  VARCHAR2
    , p7_a3  VARCHAR2
    , p7_a4  VARCHAR2
    , p7_a5  VARCHAR2
    , p7_a6  VARCHAR2
    , p7_a7  NUMBER
    , p7_a8  VARCHAR2
    , p7_a9  DATE
    , p7_a10  DATE
    , p7_a11  VARCHAR2
    , p7_a12  VARCHAR2
    , p7_a13  VARCHAR2
    , p7_a14  VARCHAR2
    , p7_a15  VARCHAR2
    , p7_a16  VARCHAR2
    , p7_a17  VARCHAR2
    , p7_a18  VARCHAR2
    , p7_a19  VARCHAR2
    , p7_a20  VARCHAR2
    , p7_a21  VARCHAR2
    , p7_a22  VARCHAR2
    , p7_a23  VARCHAR2
    , p7_a24  VARCHAR2
    , p7_a25  VARCHAR2
    , p7_a26  VARCHAR2
    , p7_a27  VARCHAR2
    , p7_a28  VARCHAR2
    , p7_a29  VARCHAR2
    , p7_a30  VARCHAR2
    , p7_a31  DATE
    , p7_a32  NUMBER
    , p7_a33  DATE
    , p7_a34  NUMBER
    , p7_a35  NUMBER
    , p7_a36  VARCHAR2
    , p7_a37  VARCHAR2
    , p7_a38  VARCHAR2
    , p7_a39  VARCHAR2
    , x_approval_rules_id out nocopy  NUMBER
  );
  procedure update_approval_rules(p_api_version  NUMBER
    , p_init_msg_list  VARCHAR2
    , p_commit  VARCHAR2
    , p_validation_level  NUMBER
    , x_return_status out nocopy  VARCHAR2
    , x_msg_count out nocopy  NUMBER
    , x_msg_data out nocopy  VARCHAR2
    , p7_a0  NUMBER
    , p7_a1  NUMBER
    , p7_a2  VARCHAR2
    , p7_a3  VARCHAR2
    , p7_a4  VARCHAR2
    , p7_a5  VARCHAR2
    , p7_a6  VARCHAR2
    , p7_a7  NUMBER
    , p7_a8  VARCHAR2
    , p7_a9  DATE
    , p7_a10  DATE
    , p7_a11  VARCHAR2
    , p7_a12  VARCHAR2
    , p7_a13  VARCHAR2
    , p7_a14  VARCHAR2
    , p7_a15  VARCHAR2
    , p7_a16  VARCHAR2
    , p7_a17  VARCHAR2
    , p7_a18  VARCHAR2
    , p7_a19  VARCHAR2
    , p7_a20  VARCHAR2
    , p7_a21  VARCHAR2
    , p7_a22  VARCHAR2
    , p7_a23  VARCHAR2
    , p7_a24  VARCHAR2
    , p7_a25  VARCHAR2
    , p7_a26  VARCHAR2
    , p7_a27  VARCHAR2
    , p7_a28  VARCHAR2
    , p7_a29  VARCHAR2
    , p7_a30  VARCHAR2
    , p7_a31  DATE
    , p7_a32  NUMBER
    , p7_a33  DATE
    , p7_a34  NUMBER
    , p7_a35  NUMBER
    , p7_a36  VARCHAR2
    , p7_a37  VARCHAR2
    , p7_a38  VARCHAR2
    , p7_a39  VARCHAR2
  );
  procedure validate_approval_rules(p_api_version  NUMBER
    , p_init_msg_list  VARCHAR2
    , p_commit  VARCHAR2
    , p_validation_level  NUMBER
    , x_return_status out nocopy  VARCHAR2
    , x_msg_count out nocopy  NUMBER
    , x_msg_data out nocopy  VARCHAR2
    , p7_a0  NUMBER
    , p7_a1  NUMBER
    , p7_a2  VARCHAR2
    , p7_a3  VARCHAR2
    , p7_a4  VARCHAR2
    , p7_a5  VARCHAR2
    , p7_a6  VARCHAR2
    , p7_a7  NUMBER
    , p7_a8  VARCHAR2
    , p7_a9  DATE
    , p7_a10  DATE
    , p7_a11  VARCHAR2
    , p7_a12  VARCHAR2
    , p7_a13  VARCHAR2
    , p7_a14  VARCHAR2
    , p7_a15  VARCHAR2
    , p7_a16  VARCHAR2
    , p7_a17  VARCHAR2
    , p7_a18  VARCHAR2
    , p7_a19  VARCHAR2
    , p7_a20  VARCHAR2
    , p7_a21  VARCHAR2
    , p7_a22  VARCHAR2
    , p7_a23  VARCHAR2
    , p7_a24  VARCHAR2
    , p7_a25  VARCHAR2
    , p7_a26  VARCHAR2
    , p7_a27  VARCHAR2
    , p7_a28  VARCHAR2
    , p7_a29  VARCHAR2
    , p7_a30  VARCHAR2
    , p7_a31  DATE
    , p7_a32  NUMBER
    , p7_a33  DATE
    , p7_a34  NUMBER
    , p7_a35  NUMBER
    , p7_a36  VARCHAR2
    , p7_a37  VARCHAR2
    , p7_a38  VARCHAR2
    , p7_a39  VARCHAR2
  );
  procedure check_approval_rules_items(p0_a0  NUMBER
    , p0_a1  NUMBER
    , p0_a2  VARCHAR2
    , p0_a3  VARCHAR2
    , p0_a4  VARCHAR2
    , p0_a5  VARCHAR2
    , p0_a6  VARCHAR2
    , p0_a7  NUMBER
    , p0_a8  VARCHAR2
    , p0_a9  DATE
    , p0_a10  DATE
    , p0_a11  VARCHAR2
    , p0_a12  VARCHAR2
    , p0_a13  VARCHAR2
    , p0_a14  VARCHAR2
    , p0_a15  VARCHAR2
    , p0_a16  VARCHAR2
    , p0_a17  VARCHAR2
    , p0_a18  VARCHAR2
    , p0_a19  VARCHAR2
    , p0_a20  VARCHAR2
    , p0_a21  VARCHAR2
    , p0_a22  VARCHAR2
    , p0_a23  VARCHAR2
    , p0_a24  VARCHAR2
    , p0_a25  VARCHAR2
    , p0_a26  VARCHAR2
    , p0_a27  VARCHAR2
    , p0_a28  VARCHAR2
    , p0_a29  VARCHAR2
    , p0_a30  VARCHAR2
    , p0_a31  DATE
    , p0_a32  NUMBER
    , p0_a33  DATE
    , p0_a34  NUMBER
    , p0_a35  NUMBER
    , p0_a36  VARCHAR2
    , p0_a37  VARCHAR2
    , p0_a38  VARCHAR2
    , p0_a39  VARCHAR2
    , p_validation_mode  VARCHAR2
    , x_return_status out nocopy  VARCHAR2
  );
  procedure check_approval_rules_record(p0_a0  NUMBER
    , p0_a1  NUMBER
    , p0_a2  VARCHAR2
    , p0_a3  VARCHAR2
    , p0_a4  VARCHAR2
    , p0_a5  VARCHAR2
    , p0_a6  VARCHAR2
    , p0_a7  NUMBER
    , p0_a8  VARCHAR2
    , p0_a9  DATE
    , p0_a10  DATE
    , p0_a11  VARCHAR2
    , p0_a12  VARCHAR2
    , p0_a13  VARCHAR2
    , p0_a14  VARCHAR2
    , p0_a15  VARCHAR2
    , p0_a16  VARCHAR2
    , p0_a17  VARCHAR2
    , p0_a18  VARCHAR2
    , p0_a19  VARCHAR2
    , p0_a20  VARCHAR2
    , p0_a21  VARCHAR2
    , p0_a22  VARCHAR2
    , p0_a23  VARCHAR2
    , p0_a24  VARCHAR2
    , p0_a25  VARCHAR2
    , p0_a26  VARCHAR2
    , p0_a27  VARCHAR2
    , p0_a28  VARCHAR2
    , p0_a29  VARCHAR2
    , p0_a30  VARCHAR2
    , p0_a31  DATE
    , p0_a32  NUMBER
    , p0_a33  DATE
    , p0_a34  NUMBER
    , p0_a35  NUMBER
    , p0_a36  VARCHAR2
    , p0_a37  VARCHAR2
    , p0_a38  VARCHAR2
    , p0_a39  VARCHAR2
    , p1_a0  NUMBER
    , p1_a1  NUMBER
    , p1_a2  VARCHAR2
    , p1_a3  VARCHAR2
    , p1_a4  VARCHAR2
    , p1_a5  VARCHAR2
    , p1_a6  VARCHAR2
    , p1_a7  NUMBER
    , p1_a8  VARCHAR2
    , p1_a9  DATE
    , p1_a10  DATE
    , p1_a11  VARCHAR2
    , p1_a12  VARCHAR2
    , p1_a13  VARCHAR2
    , p1_a14  VARCHAR2
    , p1_a15  VARCHAR2
    , p1_a16  VARCHAR2
    , p1_a17  VARCHAR2
    , p1_a18  VARCHAR2
    , p1_a19  VARCHAR2
    , p1_a20  VARCHAR2
    , p1_a21  VARCHAR2
    , p1_a22  VARCHAR2
    , p1_a23  VARCHAR2
    , p1_a24  VARCHAR2
    , p1_a25  VARCHAR2
    , p1_a26  VARCHAR2
    , p1_a27  VARCHAR2
    , p1_a28  VARCHAR2
    , p1_a29  VARCHAR2
    , p1_a30  VARCHAR2
    , p1_a31  DATE
    , p1_a32  NUMBER
    , p1_a33  DATE
    , p1_a34  NUMBER
    , p1_a35  NUMBER
    , p1_a36  VARCHAR2
    , p1_a37  VARCHAR2
    , p1_a38  VARCHAR2
    , p1_a39  VARCHAR2
    , x_return_status out nocopy  VARCHAR2
  );
  procedure complete_approval_rules_rec(p0_a0  NUMBER
    , p0_a1  NUMBER
    , p0_a2  VARCHAR2
    , p0_a3  VARCHAR2
    , p0_a4  VARCHAR2
    , p0_a5  VARCHAR2
    , p0_a6  VARCHAR2
    , p0_a7  NUMBER
    , p0_a8  VARCHAR2
    , p0_a9  DATE
    , p0_a10  DATE
    , p0_a11  VARCHAR2
    , p0_a12  VARCHAR2
    , p0_a13  VARCHAR2
    , p0_a14  VARCHAR2
    , p0_a15  VARCHAR2
    , p0_a16  VARCHAR2
    , p0_a17  VARCHAR2
    , p0_a18  VARCHAR2
    , p0_a19  VARCHAR2
    , p0_a20  VARCHAR2
    , p0_a21  VARCHAR2
    , p0_a22  VARCHAR2
    , p0_a23  VARCHAR2
    , p0_a24  VARCHAR2
    , p0_a25  VARCHAR2
    , p0_a26  VARCHAR2
    , p0_a27  VARCHAR2
    , p0_a28  VARCHAR2
    , p0_a29  VARCHAR2
    , p0_a30  VARCHAR2
    , p0_a31  DATE
    , p0_a32  NUMBER
    , p0_a33  DATE
    , p0_a34  NUMBER
    , p0_a35  NUMBER
    , p0_a36  VARCHAR2
    , p0_a37  VARCHAR2
    , p0_a38  VARCHAR2
    , p0_a39  VARCHAR2
    , p1_a0 out nocopy  NUMBER
    , p1_a1 out nocopy  NUMBER
    , p1_a2 out nocopy  VARCHAR2
    , p1_a3 out nocopy  VARCHAR2
    , p1_a4 out nocopy  VARCHAR2
    , p1_a5 out nocopy  VARCHAR2
    , p1_a6 out nocopy  VARCHAR2
    , p1_a7 out nocopy  NUMBER
    , p1_a8 out nocopy  VARCHAR2
    , p1_a9 out nocopy  DATE
    , p1_a10 out nocopy  DATE
    , p1_a11 out nocopy  VARCHAR2
    , p1_a12 out nocopy  VARCHAR2
    , p1_a13 out nocopy  VARCHAR2
    , p1_a14 out nocopy  VARCHAR2
    , p1_a15 out nocopy  VARCHAR2
    , p1_a16 out nocopy  VARCHAR2
    , p1_a17 out nocopy  VARCHAR2
    , p1_a18 out nocopy  VARCHAR2
    , p1_a19 out nocopy  VARCHAR2
    , p1_a20 out nocopy  VARCHAR2
    , p1_a21 out nocopy  VARCHAR2
    , p1_a22 out nocopy  VARCHAR2
    , p1_a23 out nocopy  VARCHAR2
    , p1_a24 out nocopy  VARCHAR2
    , p1_a25 out nocopy  VARCHAR2
    , p1_a26 out nocopy  VARCHAR2
    , p1_a27 out nocopy  VARCHAR2
    , p1_a28 out nocopy  VARCHAR2
    , p1_a29 out nocopy  VARCHAR2
    , p1_a30 out nocopy  VARCHAR2
    , p1_a31 out nocopy  DATE
    , p1_a32 out nocopy  NUMBER
    , p1_a33 out nocopy  DATE
    , p1_a34 out nocopy  NUMBER
    , p1_a35 out nocopy  NUMBER
    , p1_a36 out nocopy  VARCHAR2
    , p1_a37 out nocopy  VARCHAR2
    , p1_a38 out nocopy  VARCHAR2
    , p1_a39 out nocopy  VARCHAR2
  );
  procedure create_approvers(p_api_version  NUMBER
    , p_init_msg_list  VARCHAR2
    , p_commit  VARCHAR2
    , p_validation_level  NUMBER
    , x_return_status out nocopy  VARCHAR2
    , x_msg_count out nocopy  NUMBER
    , x_msg_data out nocopy  VARCHAR2
    , p7_a0  NUMBER
    , p7_a1  NUMBER
    , p7_a2  NUMBER
    , p7_a3  VARCHAR2
    , p7_a4  NUMBER
    , p7_a5  NUMBER
    , p7_a6  VARCHAR2
    , p7_a7  DATE
    , p7_a8  NUMBER
    , p7_a9  DATE
    , p7_a10  NUMBER
    , p7_a11  NUMBER
    , p7_a12  VARCHAR2
    , p7_a13  VARCHAR2
    , p7_a14  VARCHAR2
    , p7_a15  VARCHAR2
    , p7_a16  VARCHAR2
    , p7_a17  VARCHAR2
    , p7_a18  VARCHAR2
    , p7_a19  VARCHAR2
    , p7_a20  VARCHAR2
    , p7_a21  VARCHAR2
    , p7_a22  VARCHAR2
    , p7_a23  VARCHAR2
    , p7_a24  VARCHAR2
    , p7_a25  VARCHAR2
    , p7_a26  VARCHAR2
    , p7_a27  VARCHAR2
    , p7_a28  VARCHAR2
    , x_approval_approver_id out nocopy  NUMBER
  );
  procedure update_approvers(p_api_version  NUMBER
    , p_init_msg_list  VARCHAR2
    , p_commit  VARCHAR2
    , p_validation_level  NUMBER
    , p4_a0  NUMBER
    , p4_a1  NUMBER
    , p4_a2  NUMBER
    , p4_a3  VARCHAR2
    , p4_a4  NUMBER
    , p4_a5  NUMBER
    , p4_a6  VARCHAR2
    , p4_a7  DATE
    , p4_a8  NUMBER
    , p4_a9  DATE
    , p4_a10  NUMBER
    , p4_a11  NUMBER
    , p4_a12  VARCHAR2
    , p4_a13  VARCHAR2
    , p4_a14  VARCHAR2
    , p4_a15  VARCHAR2
    , p4_a16  VARCHAR2
    , p4_a17  VARCHAR2
    , p4_a18  VARCHAR2
    , p4_a19  VARCHAR2
    , p4_a20  VARCHAR2
    , p4_a21  VARCHAR2
    , p4_a22  VARCHAR2
    , p4_a23  VARCHAR2
    , p4_a24  VARCHAR2
    , p4_a25  VARCHAR2
    , p4_a26  VARCHAR2
    , p4_a27  VARCHAR2
    , p4_a28  VARCHAR2
    , x_return_status out nocopy  VARCHAR2
    , x_msg_count out nocopy  NUMBER
    , x_msg_data out nocopy  VARCHAR2
  );
  procedure validate_approvers(p_api_version  NUMBER
    , p_init_msg_list  VARCHAR2
    , p_commit  VARCHAR2
    , p_validation_level  NUMBER
    , x_return_status out nocopy  VARCHAR2
    , x_msg_count out nocopy  NUMBER
    , x_msg_data out nocopy  VARCHAR2
    , p7_a0  NUMBER
    , p7_a1  NUMBER
    , p7_a2  NUMBER
    , p7_a3  VARCHAR2
    , p7_a4  NUMBER
    , p7_a5  NUMBER
    , p7_a6  VARCHAR2
    , p7_a7  DATE
    , p7_a8  NUMBER
    , p7_a9  DATE
    , p7_a10  NUMBER
    , p7_a11  NUMBER
    , p7_a12  VARCHAR2
    , p7_a13  VARCHAR2
    , p7_a14  VARCHAR2
    , p7_a15  VARCHAR2
    , p7_a16  VARCHAR2
    , p7_a17  VARCHAR2
    , p7_a18  VARCHAR2
    , p7_a19  VARCHAR2
    , p7_a20  VARCHAR2
    , p7_a21  VARCHAR2
    , p7_a22  VARCHAR2
    , p7_a23  VARCHAR2
    , p7_a24  VARCHAR2
    , p7_a25  VARCHAR2
    , p7_a26  VARCHAR2
    , p7_a27  VARCHAR2
    , p7_a28  VARCHAR2
  );
  procedure check_approvers_items(p_validation_mode  VARCHAR2
    , p1_a0  NUMBER
    , p1_a1  NUMBER
    , p1_a2  NUMBER
    , p1_a3  VARCHAR2
    , p1_a4  NUMBER
    , p1_a5  NUMBER
    , p1_a6  VARCHAR2
    , p1_a7  DATE
    , p1_a8  NUMBER
    , p1_a9  DATE
    , p1_a10  NUMBER
    , p1_a11  NUMBER
    , p1_a12  VARCHAR2
    , p1_a13  VARCHAR2
    , p1_a14  VARCHAR2
    , p1_a15  VARCHAR2
    , p1_a16  VARCHAR2
    , p1_a17  VARCHAR2
    , p1_a18  VARCHAR2
    , p1_a19  VARCHAR2
    , p1_a20  VARCHAR2
    , p1_a21  VARCHAR2
    , p1_a22  VARCHAR2
    , p1_a23  VARCHAR2
    , p1_a24  VARCHAR2
    , p1_a25  VARCHAR2
    , p1_a26  VARCHAR2
    , p1_a27  VARCHAR2
    , p1_a28  VARCHAR2
    , x_return_status out nocopy  VARCHAR2
  );
  procedure complete_approvers_rec(p0_a0  NUMBER
    , p0_a1  NUMBER
    , p0_a2  NUMBER
    , p0_a3  VARCHAR2
    , p0_a4  NUMBER
    , p0_a5  NUMBER
    , p0_a6  VARCHAR2
    , p0_a7  DATE
    , p0_a8  NUMBER
    , p0_a9  DATE
    , p0_a10  NUMBER
    , p0_a11  NUMBER
    , p0_a12  VARCHAR2
    , p0_a13  VARCHAR2
    , p0_a14  VARCHAR2
    , p0_a15  VARCHAR2
    , p0_a16  VARCHAR2
    , p0_a17  VARCHAR2
    , p0_a18  VARCHAR2
    , p0_a19  VARCHAR2
    , p0_a20  VARCHAR2
    , p0_a21  VARCHAR2
    , p0_a22  VARCHAR2
    , p0_a23  VARCHAR2
    , p0_a24  VARCHAR2
    , p0_a25  VARCHAR2
    , p0_a26  VARCHAR2
    , p0_a27  VARCHAR2
    , p0_a28  VARCHAR2
    , p1_a0 out nocopy  NUMBER
    , p1_a1 out nocopy  NUMBER
    , p1_a2 out nocopy  NUMBER
    , p1_a3 out nocopy  VARCHAR2
    , p1_a4 out nocopy  NUMBER
    , p1_a5 out nocopy  NUMBER
    , p1_a6 out nocopy  VARCHAR2
    , p1_a7 out nocopy  DATE
    , p1_a8 out nocopy  NUMBER
    , p1_a9 out nocopy  DATE
    , p1_a10 out nocopy  NUMBER
    , p1_a11 out nocopy  NUMBER
    , p1_a12 out nocopy  VARCHAR2
    , p1_a13 out nocopy  VARCHAR2
    , p1_a14 out nocopy  VARCHAR2
    , p1_a15 out nocopy  VARCHAR2
    , p1_a16 out nocopy  VARCHAR2
    , p1_a17 out nocopy  VARCHAR2
    , p1_a18 out nocopy  VARCHAR2
    , p1_a19 out nocopy  VARCHAR2
    , p1_a20 out nocopy  VARCHAR2
    , p1_a21 out nocopy  VARCHAR2
    , p1_a22 out nocopy  VARCHAR2
    , p1_a23 out nocopy  VARCHAR2
    , p1_a24 out nocopy  VARCHAR2
    , p1_a25 out nocopy  VARCHAR2
    , p1_a26 out nocopy  VARCHAR2
    , p1_a27 out nocopy  VARCHAR2
    , p1_a28 out nocopy  VARCHAR2
  );
end ahl_approvals_pvt_w;

CREATE OR REPLACE EDITIONABLE PACKAGE BODY "APPS"."AHL_APPROVALS_PVT_W" as
  /* $Header: AHLWAPRB.pls 120.1.12020000.2 2019/10/23 00:20:25 sracha ship $ */
  rosetta_g_mistake_date date := to_date('01/01/+4713', 'MM/DD/SYYYY');
  rosetta_g_miss_date date := to_date('01/01/-4712', 'MM/DD/SYYYY');
  rosetta_g_mistake_date_high date := to_date('01/01/+4710', 'MM/DD/SYYYY');
  rosetta_g_mistake_date_low date := to_date('01/01/-4710', 'MM/DD/SYYYY');

  -- this is to workaround the JDBC bug regarding IN DATE of value GMiss
  function rosetta_g_miss_date_in_map(d date) return date as
  begin
    if d > rosetta_g_mistake_date_high then return fnd_api.g_miss_date; end if;
    if d < rosetta_g_mistake_date_low then return fnd_api.g_miss_date; end if;
    return d;
  end;

  procedure rosetta_table_copy_in_p2(t out nocopy ahl_approvals_pvt.approvers_tbl, a0 JTF_NUMBER_TABLE
    , a1 JTF_NUMBER_TABLE
    , a2 JTF_NUMBER_TABLE
    , a3 JTF_VARCHAR2_TABLE_100
    , a4 JTF_NUMBER_TABLE
    , a5 JTF_NUMBER_TABLE
    , a6 JTF_VARCHAR2_TABLE_100
    , a7 JTF_DATE_TABLE
    , a8 JTF_NUMBER_TABLE
    , a9 JTF_DATE_TABLE
    , a10 JTF_NUMBER_TABLE
    , a11 JTF_NUMBER_TABLE
    , a12 JTF_VARCHAR2_TABLE_100
    , a13 JTF_VARCHAR2_TABLE_200
    , a14 JTF_VARCHAR2_TABLE_200
    , a15 JTF_VARCHAR2_TABLE_200
    , a16 JTF_VARCHAR2_TABLE_200
    , a17 JTF_VARCHAR2_TABLE_200
    , a18 JTF_VARCHAR2_TABLE_200
    , a19 JTF_VARCHAR2_TABLE_200
    , a20 JTF_VARCHAR2_TABLE_200
    , a21 JTF_VARCHAR2_TABLE_200
    , a22 JTF_VARCHAR2_TABLE_200
    , a23 JTF_VARCHAR2_TABLE_200
    , a24 JTF_VARCHAR2_TABLE_200
    , a25 JTF_VARCHAR2_TABLE_200
    , a26 JTF_VARCHAR2_TABLE_200
    , a27 JTF_VARCHAR2_TABLE_200
    , a28 JTF_VARCHAR2_TABLE_100
    ) as
    ddindx binary_integer; indx binary_integer;
  begin
  if a0 is not null and a0.count > 0 then
      if a0.count > 0 then
        indx := a0.first;
        ddindx := 1;
        while true loop
          t(ddindx).approval_approver_id := a0(indx);
          t(ddindx).object_version_number := a1(indx);
          t(ddindx).approval_rule_id := a2(indx);
          t(ddindx).approver_type_code := a3(indx);
          t(ddindx).approver_sequence := a4(indx);
          t(ddindx).approver_id := a5(indx);
          t(ddindx).approver_name := a6(indx);
          t(ddindx).last_update_date := rosetta_g_miss_date_in_map(a7(indx));
          t(ddindx).last_updated_by := a8(indx);
          t(ddindx).creation_date := rosetta_g_miss_date_in_map(a9(indx));
          t(ddindx).created_by := a10(indx);
          t(ddindx).last_update_login := a11(indx);
          t(ddindx).attribute_category := a12(indx);
          t(ddindx).attribute1 := a13(indx);
          t(ddindx).attribute2 := a14(indx);
          t(ddindx).attribute3 := a15(indx);
          t(ddindx).attribute4 := a16(indx);
          t(ddindx).attribute5 := a17(indx);
          t(ddindx).attribute6 := a18(indx);
          t(ddindx).attribute7 := a19(indx);
          t(ddindx).attribute8 := a20(indx);
          t(ddindx).attribute9 := a21(indx);
          t(ddindx).attribute10 := a22(indx);
          t(ddindx).attribute11 := a23(indx);
          t(ddindx).attribute12 := a24(indx);
          t(ddindx).attribute13 := a25(indx);
          t(ddindx).attribute14 := a26(indx);
          t(ddindx).attribute15 := a27(indx);
          t(ddindx).operation_flag := a28(indx);
          ddindx := ddindx+1;
          if a0.last =indx
            then exit;
          end if;
          indx := a0.next(indx);
        end loop;
      end if;
   end if;
  end rosetta_table_copy_in_p2;
  procedure rosetta_table_copy_out_p2(t ahl_approvals_pvt.approvers_tbl, a0 out nocopy JTF_NUMBER_TABLE
    , a1 out nocopy JTF_NUMBER_TABLE
    , a2 out nocopy JTF_NUMBER_TABLE
    , a3 out nocopy JTF_VARCHAR2_TABLE_100
    , a4 out nocopy JTF_NUMBER_TABLE
    , a5 out nocopy JTF_NUMBER_TABLE
    , a6 out nocopy JTF_VARCHAR2_TABLE_100
    , a7 out nocopy JTF_DATE_TABLE
    , a8 out nocopy JTF_NUMBER_TABLE
    , a9 out nocopy JTF_DATE_TABLE
    , a10 out nocopy JTF_NUMBER_TABLE
    , a11 out nocopy JTF_NUMBER_TABLE
    , a12 out nocopy JTF_VARCHAR2_TABLE_100
    , a13 out nocopy JTF_VARCHAR2_TABLE_200
    , a14 out nocopy JTF_VARCHAR2_TABLE_200
    , a15 out nocopy JTF_VARCHAR2_TABLE_200
    , a16 out nocopy JTF_VARCHAR2_TABLE_200
    , a17 out nocopy JTF_VARCHAR2_TABLE_200
    , a18 out nocopy JTF_VARCHAR2_TABLE_200
    , a19 out nocopy JTF_VARCHAR2_TABLE_200
    , a20 out nocopy JTF_VARCHAR2_TABLE_200
    , a21 out nocopy JTF_VARCHAR2_TABLE_200
    , a22 out nocopy JTF_VARCHAR2_TABLE_200
    , a23 out nocopy JTF_VARCHAR2_TABLE_200
    , a24 out nocopy JTF_VARCHAR2_TABLE_200
    , a25 out nocopy JTF_VARCHAR2_TABLE_200
    , a26 out nocopy JTF_VARCHAR2_TABLE_200
    , a27 out nocopy JTF_VARCHAR2_TABLE_200
    , a28 out nocopy JTF_VARCHAR2_TABLE_100
    ) as
    ddindx binary_integer; indx binary_integer;
  begin
  if t is null or t.count = 0 then
    a0 := JTF_NUMBER_TABLE();
    a1 := JTF_NUMBER_TABLE();
    a2 := JTF_NUMBER_TABLE();
    a3 := JTF_VARCHAR2_TABLE_100();
    a4 := JTF_NUMBER_TABLE();
    a5 := JTF_NUMBER_TABLE();
    a6 := JTF_VARCHAR2_TABLE_100();
    a7 := JTF_DATE_TABLE();
    a8 := JTF_NUMBER_TABLE();
    a9 := JTF_DATE_TABLE();
    a10 := JTF_NUMBER_TABLE();
    a11 := JTF_NUMBER_TABLE();
    a12 := JTF_VARCHAR2_TABLE_100();
    a13 := JTF_VARCHAR2_TABLE_200();
    a14 := JTF_VARCHAR2_TABLE_200();
    a15 := JTF_VARCHAR2_TABLE_200();
    a16 := JTF_VARCHAR2_TABLE_200();
    a17 := JTF_VARCHAR2_TABLE_200();
    a18 := JTF_VARCHAR2_TABLE_200();
    a19 := JTF_VARCHAR2_TABLE_200();
    a20 := JTF_VARCHAR2_TABLE_200();
    a21 := JTF_VARCHAR2_TABLE_200();
    a22 := JTF_VARCHAR2_TABLE_200();
    a23 := JTF_VARCHAR2_TABLE_200();
    a24 := JTF_VARCHAR2_TABLE_200();
    a25 := JTF_VARCHAR2_TABLE_200();
    a26 := JTF_VARCHAR2_TABLE_200();
    a27 := JTF_VARCHAR2_TABLE_200();
    a28 := JTF_VARCHAR2_TABLE_100();
  else
      a0 := JTF_NUMBER_TABLE();
      a1 := JTF_NUMBER_TABLE();
      a2 := JTF_NUMBER_TABLE();
      a3 := JTF_VARCHAR2_TABLE_100();
      a4 := JTF_NUMBER_TABLE();
      a5 := JTF_NUMBER_TABLE();
      a6 := JTF_VARCHAR2_TABLE_100();
      a7 := JTF_DATE_TABLE();
      a8 := JTF_NUMBER_TABLE();
      a9 := JTF_DATE_TABLE();
      a10 := JTF_NUMBER_TABLE();
      a11 := JTF_NUMBER_TABLE();
      a12 := JTF_VARCHAR2_TABLE_100();
      a13 := JTF_VARCHAR2_TABLE_200();
      a14 := JTF_VARCHAR2_TABLE_200();
      a15 := JTF_VARCHAR2_TABLE_200();
      a16 := JTF_VARCHAR2_TABLE_200();
      a17 := JTF_VARCHAR2_TABLE_200();
      a18 := JTF_VARCHAR2_TABLE_200();
      a19 := JTF_VARCHAR2_TABLE_200();
      a20 := JTF_VARCHAR2_TABLE_200();
      a21 := JTF_VARCHAR2_TABLE_200();
      a22 := JTF_VARCHAR2_TABLE_200();
      a23 := JTF_VARCHAR2_TABLE_200();
      a24 := JTF_VARCHAR2_TABLE_200();
      a25 := JTF_VARCHAR2_TABLE_200();
      a26 := JTF_VARCHAR2_TABLE_200();
      a27 := JTF_VARCHAR2_TABLE_200();
      a28 := JTF_VARCHAR2_TABLE_100();
      if t.count > 0 then
        a0.extend(t.count);
        a1.extend(t.count);
        a2.extend(t.count);
        a3.extend(t.count);
        a4.extend(t.count);
        a5.extend(t.count);
        a6.extend(t.count);
        a7.extend(t.count);
        a8.extend(t.count);
        a9.extend(t.count);
        a10.extend(t.count);
        a11.extend(t.count);
        a12.extend(t.count);
        a13.extend(t.count);
        a14.extend(t.count);
        a15.extend(t.count);
        a16.extend(t.count);
        a17.extend(t.count);
        a18.extend(t.count);
        a19.extend(t.count);
        a20.extend(t.count);
        a21.extend(t.count);
        a22.extend(t.count);
        a23.extend(t.count);
        a24.extend(t.count);
        a25.extend(t.count);
        a26.extend(t.count);
        a27.extend(t.count);
        a28.extend(t.count);
        ddindx := t.first;
        indx := 1;
        while true loop
          a0(indx) := t(ddindx).approval_approver_id;
          a1(indx) := t(ddindx).object_version_number;
          a2(indx) := t(ddindx).approval_rule_id;
          a3(indx) := t(ddindx).approver_type_code;
          a4(indx) := t(ddindx).approver_sequence;
          a5(indx) := t(ddindx).approver_id;
          a6(indx) := t(ddindx).approver_name;
          a7(indx) := t(ddindx).last_update_date;
          a8(indx) := t(ddindx).last_updated_by;
          a9(indx) := t(ddindx).creation_date;
          a10(indx) := t(ddindx).created_by;
          a11(indx) := t(ddindx).last_update_login;
          a12(indx) := t(ddindx).attribute_category;
          a13(indx) := t(ddindx).attribute1;
          a14(indx) := t(ddindx).attribute2;
          a15(indx) := t(ddindx).attribute3;
          a16(indx) := t(ddindx).attribute4;
          a17(indx) := t(ddindx).attribute5;
          a18(indx) := t(ddindx).attribute6;
          a19(indx) := t(ddindx).attribute7;
          a20(indx) := t(ddindx).attribute8;
          a21(indx) := t(ddindx).attribute9;
          a22(indx) := t(ddindx).attribute10;
          a23(indx) := t(ddindx).attribute11;
          a24(indx) := t(ddindx).attribute12;
          a25(indx) := t(ddindx).attribute13;
          a26(indx) := t(ddindx).attribute14;
          a27(indx) := t(ddindx).attribute15;
          a28(indx) := t(ddindx).operation_flag;
          indx := indx+1;
          if t.last =ddindx
            then exit;
          end if;
          ddindx := t.next(ddindx);
        end loop;
      end if;
   end if;
  end rosetta_table_copy_out_p2;

  procedure process_approvals(p_api_version  NUMBER
    , p_init_msg_list  VARCHAR2
    , p_commit  VARCHAR2
    , p_validation_level  NUMBER
    , p4_a0 in out nocopy  NUMBER
    , p4_a1 in out nocopy  NUMBER
    , p4_a2 in out nocopy  VARCHAR2
    , p4_a3 in out nocopy  VARCHAR2
    , p4_a4 in out nocopy  VARCHAR2
    , p4_a5 in out nocopy  VARCHAR2
    , p4_a6 in out nocopy  VARCHAR2
    , p4_a7 in out nocopy  NUMBER
    , p4_a8 in out nocopy  VARCHAR2
    , p4_a9 in out nocopy  DATE
    , p4_a10 in out nocopy  DATE
    , p4_a11 in out nocopy  VARCHAR2
    , p4_a12 in out nocopy  VARCHAR2
    , p4_a13 in out nocopy  VARCHAR2
    , p4_a14 in out nocopy  VARCHAR2
    , p4_a15 in out nocopy  VARCHAR2
    , p4_a16 in out nocopy  VARCHAR2
    , p4_a17 in out nocopy  VARCHAR2
    , p4_a18 in out nocopy  VARCHAR2
    , p4_a19 in out nocopy  VARCHAR2
    , p4_a20 in out nocopy  VARCHAR2
    , p4_a21 in out nocopy  VARCHAR2
    , p4_a22 in out nocopy  VARCHAR2
    , p4_a23 in out nocopy  VARCHAR2
    , p4_a24 in out nocopy  VARCHAR2
    , p4_a25 in out nocopy  VARCHAR2
    , p4_a26 in out nocopy  VARCHAR2
    , p4_a27 in out nocopy  VARCHAR2
    , p4_a28 in out nocopy  VARCHAR2
    , p4_a29 in out nocopy  VARCHAR2
    , p4_a30 in out nocopy  VARCHAR2
    , p4_a31 in out nocopy  DATE
    , p4_a32 in out nocopy  NUMBER
    , p4_a33 in out nocopy  DATE
    , p4_a34 in out nocopy  NUMBER
    , p4_a35 in out nocopy  NUMBER
    , p4_a36 in out nocopy  VARCHAR2
    , p4_a37 in out nocopy  VARCHAR2
    , p4_a38 in out nocopy  VARCHAR2
    , p4_a39 in out nocopy  VARCHAR2
    , p5_a0 in out nocopy JTF_NUMBER_TABLE
    , p5_a1 in out nocopy JTF_NUMBER_TABLE
    , p5_a2 in out nocopy JTF_NUMBER_TABLE
    , p5_a3 in out nocopy JTF_VARCHAR2_TABLE_100
    , p5_a4 in out nocopy JTF_NUMBER_TABLE
    , p5_a5 in out nocopy JTF_NUMBER_TABLE
    , p5_a6 in out nocopy JTF_VARCHAR2_TABLE_100
    , p5_a7 in out nocopy JTF_DATE_TABLE
    , p5_a8 in out nocopy JTF_NUMBER_TABLE
    , p5_a9 in out nocopy JTF_DATE_TABLE
    , p5_a10 in out nocopy JTF_NUMBER_TABLE
    , p5_a11 in out nocopy JTF_NUMBER_TABLE
    , p5_a12 in out nocopy JTF_VARCHAR2_TABLE_100
    , p5_a13 in out nocopy JTF_VARCHAR2_TABLE_200
    , p5_a14 in out nocopy JTF_VARCHAR2_TABLE_200
    , p5_a15 in out nocopy JTF_VARCHAR2_TABLE_200
    , p5_a16 in out nocopy JTF_VARCHAR2_TABLE_200
    , p5_a17 in out nocopy JTF_VARCHAR2_TABLE_200
    , p5_a18 in out nocopy JTF_VARCHAR2_TABLE_200
    , p5_a19 in out nocopy JTF_VARCHAR2_TABLE_200
    , p5_a20 in out nocopy JTF_VARCHAR2_TABLE_200
    , p5_a21 in out nocopy JTF_VARCHAR2_TABLE_200
    , p5_a22 in out nocopy JTF_VARCHAR2_TABLE_200
    , p5_a23 in out nocopy JTF_VARCHAR2_TABLE_200
    , p5_a24 in out nocopy JTF_VARCHAR2_TABLE_200
    , p5_a25 in out nocopy JTF_VARCHAR2_TABLE_200
    , p5_a26 in out nocopy JTF_VARCHAR2_TABLE_200
    , p5_a27 in out nocopy JTF_VARCHAR2_TABLE_200
    , p5_a28 in out nocopy JTF_VARCHAR2_TABLE_100
    , x_return_status out nocopy  VARCHAR2
    , x_msg_count out nocopy  NUMBER
    , x_msg_data out nocopy  VARCHAR2
  )

  as
    ddp_x_approval_rules_rec ahl_approvals_pvt.approval_rules_rec_type;
    ddp_x_approvers_tbl ahl_approvals_pvt.approvers_tbl;
    ddindx binary_integer; indx binary_integer;
  begin

    -- copy data to the local IN or IN-OUT args, if any




    ddp_x_approval_rules_rec.approval_rule_id := p4_a0;
    ddp_x_approval_rules_rec.object_version_number := p4_a1;
    ddp_x_approval_rules_rec.approval_object_code := p4_a2;
    ddp_x_approval_rules_rec.approval_priority_code := p4_a3;
    ddp_x_approval_rules_rec.approval_type_code := p4_a4;
    ddp_x_approval_rules_rec.application_usg_code := p4_a5;
    ddp_x_approval_rules_rec.application_usg := p4_a6;
    ddp_x_approval_rules_rec.operating_unit_id := p4_a7;
    ddp_x_approval_rules_rec.operating_name := p4_a8;
    ddp_x_approval_rules_rec.active_start_date := rosetta_g_miss_date_in_map(p4_a9);
    ddp_x_approval_rules_rec.active_end_date := rosetta_g_miss_date_in_map(p4_a10);
    ddp_x_approval_rules_rec.status_code := p4_a11;
    ddp_x_approval_rules_rec.seeded_flag := p4_a12;
    ddp_x_approval_rules_rec.attribute_category := p4_a13;
    ddp_x_approval_rules_rec.attribute1 := p4_a14;
    ddp_x_approval_rules_rec.attribute2 := p4_a15;
    ddp_x_approval_rules_rec.attribute3 := p4_a16;
    ddp_x_approval_rules_rec.attribute4 := p4_a17;
    ddp_x_approval_rules_rec.attribute5 := p4_a18;
    ddp_x_approval_rules_rec.attribute6 := p4_a19;
    ddp_x_approval_rules_rec.attribute7 := p4_a20;
    ddp_x_approval_rules_rec.attribute8 := p4_a21;
    ddp_x_approval_rules_rec.attribute9 := p4_a22;
    ddp_x_approval_rules_rec.attribute10 := p4_a23;
    ddp_x_approval_rules_rec.attribute11 := p4_a24;
    ddp_x_approval_rules_rec.attribute12 := p4_a25;
    ddp_x_approval_rules_rec.attribute13 := p4_a26;
    ddp_x_approval_rules_rec.attribute14 := p4_a27;
    ddp_x_approval_rules_rec.attribute15 := p4_a28;
    ddp_x_approval_rules_rec.approval_rule_name := p4_a29;
    ddp_x_approval_rules_rec.description := p4_a30;
    ddp_x_approval_rules_rec.creation_date := rosetta_g_miss_date_in_map(p4_a31);
    ddp_x_approval_rules_rec.created_by := p4_a32;
    ddp_x_approval_rules_rec.last_update_date := rosetta_g_miss_date_in_map(p4_a33);
    ddp_x_approval_rules_rec.last_updated_by := p4_a34;
    ddp_x_approval_rules_rec.last_update_login := p4_a35;
    ddp_x_approval_rules_rec.operation_flag := p4_a36;
    ddp_x_approval_rules_rec.program_type_code := p4_a37;
    ddp_x_approval_rules_rec.program_subtype_code := p4_a38;
    ddp_x_approval_rules_rec.revision_type_code := p4_a39;

    ahl_approvals_pvt_w.rosetta_table_copy_in_p2(ddp_x_approvers_tbl, p5_a0
      , p5_a1
      , p5_a2
      , p5_a3
      , p5_a4
      , p5_a5
      , p5_a6
      , p5_a7
      , p5_a8
      , p5_a9
      , p5_a10
      , p5_a11
      , p5_a12
      , p5_a13
      , p5_a14
      , p5_a15
      , p5_a16
      , p5_a17
      , p5_a18
      , p5_a19
      , p5_a20
      , p5_a21
      , p5_a22
      , p5_a23
      , p5_a24
      , p5_a25
      , p5_a26
      , p5_a27
      , p5_a28
      );




    -- here's the delegated call to the old PL/SQL routine
    ahl_approvals_pvt.process_approvals(p_api_version,
      p_init_msg_list,
      p_commit,
      p_validation_level,
      ddp_x_approval_rules_rec,
      ddp_x_approvers_tbl,
      x_return_status,
      x_msg_count,
      x_msg_data);

    -- copy data back from the local variables to OUT or IN-OUT args, if any




    p4_a0 := ddp_x_approval_rules_rec.approval_rule_id;
    p4_a1 := ddp_x_approval_rules_rec.object_version_number;
    p4_a2 := ddp_x_approval_rules_rec.approval_object_code;
    p4_a3 := ddp_x_approval_rules_rec.approval_priority_code;
    p4_a4 := ddp_x_approval_rules_rec.approval_type_code;
    p4_a5 := ddp_x_approval_rules_rec.application_usg_code;
    p4_a6 := ddp_x_approval_rules_rec.application_usg;
    p4_a7 := ddp_x_approval_rules_rec.operating_unit_id;
    p4_a8 := ddp_x_approval_rules_rec.operating_name;
    p4_a9 := ddp_x_approval_rules_rec.active_start_date;
    p4_a10 := ddp_x_approval_rules_rec.active_end_date;
    p4_a11 := ddp_x_approval_rules_rec.status_code;
    p4_a12 := ddp_x_approval_rules_rec.seeded_flag;
    p4_a13 := ddp_x_approval_rules_rec.attribute_category;
    p4_a14 := ddp_x_approval_rules_rec.attribute1;
    p4_a15 := ddp_x_approval_rules_rec.attribute2;
    p4_a16 := ddp_x_approval_rules_rec.attribute3;
    p4_a17 := ddp_x_approval_rules_rec.attribute4;
    p4_a18 := ddp_x_approval_rules_rec.attribute5;
    p4_a19 := ddp_x_approval_rules_rec.attribute6;
    p4_a20 := ddp_x_approval_rules_rec.attribute7;
    p4_a21 := ddp_x_approval_rules_rec.attribute8;
    p4_a22 := ddp_x_approval_rules_rec.attribute9;
    p4_a23 := ddp_x_approval_rules_rec.attribute10;
    p4_a24 := ddp_x_approval_rules_rec.attribute11;
    p4_a25 := ddp_x_approval_rules_rec.attribute12;
    p4_a26 := ddp_x_approval_rules_rec.attribute13;
    p4_a27 := ddp_x_approval_rules_rec.attribute14;
    p4_a28 := ddp_x_approval_rules_rec.attribute15;
    p4_a29 := ddp_x_approval_rules_rec.approval_rule_name;
    p4_a30 := ddp_x_approval_rules_rec.description;
    p4_a31 := ddp_x_approval_rules_rec.creation_date;
    p4_a32 := ddp_x_approval_rules_rec.created_by;
    p4_a33 := ddp_x_approval_rules_rec.last_update_date;
    p4_a34 := ddp_x_approval_rules_rec.last_updated_by;
    p4_a35 := ddp_x_approval_rules_rec.last_update_login;
    p4_a36 := ddp_x_approval_rules_rec.operation_flag;
    p4_a37 := ddp_x_approval_rules_rec.program_type_code;
    p4_a38 := ddp_x_approval_rules_rec.program_subtype_code;
    p4_a39 := ddp_x_approval_rules_rec.revision_type_code;

    ahl_approvals_pvt_w.rosetta_table_copy_out_p2(ddp_x_approvers_tbl, p5_a0
      , p5_a1
      , p5_a2
      , p5_a3
      , p5_a4
      , p5_a5
      , p5_a6
      , p5_a7
      , p5_a8
      , p5_a9
      , p5_a10
      , p5_a11
      , p5_a12
      , p5_a13
      , p5_a14
      , p5_a15
      , p5_a16
      , p5_a17
      , p5_a18
      , p5_a19
      , p5_a20
      , p5_a21
      , p5_a22
      , p5_a23
      , p5_a24
      , p5_a25
      , p5_a26
      , p5_a27
      , p5_a28
      );



  end;

  procedure create_approval_rules(p_api_version  NUMBER
    , p_init_msg_list  VARCHAR2
    , p_commit  VARCHAR2
    , p_validation_level  NUMBER
    , x_return_status out nocopy  VARCHAR2
    , x_msg_count out nocopy  NUMBER
    , x_msg_data out nocopy  VARCHAR2
    , p7_a0  NUMBER
    , p7_a1  NUMBER
    , p7_a2  VARCHAR2
    , p7_a3  VARCHAR2
    , p7_a4  VARCHAR2
    , p7_a5  VARCHAR2
    , p7_a6  VARCHAR2
    , p7_a7  NUMBER
    , p7_a8  VARCHAR2
    , p7_a9  DATE
    , p7_a10  DATE
    , p7_a11  VARCHAR2
    , p7_a12  VARCHAR2
    , p7_a13  VARCHAR2
    , p7_a14  VARCHAR2
    , p7_a15  VARCHAR2
    , p7_a16  VARCHAR2
    , p7_a17  VARCHAR2
    , p7_a18  VARCHAR2
    , p7_a19  VARCHAR2
    , p7_a20  VARCHAR2
    , p7_a21  VARCHAR2
    , p7_a22  VARCHAR2
    , p7_a23  VARCHAR2
    , p7_a24  VARCHAR2
    , p7_a25  VARCHAR2
    , p7_a26  VARCHAR2
    , p7_a27  VARCHAR2
    , p7_a28  VARCHAR2
    , p7_a29  VARCHAR2
    , p7_a30  VARCHAR2
    , p7_a31  DATE
    , p7_a32  NUMBER
    , p7_a33  DATE
    , p7_a34  NUMBER
    , p7_a35  NUMBER
    , p7_a36  VARCHAR2
    , p7_a37  VARCHAR2
    , p7_a38  VARCHAR2
    , p7_a39  VARCHAR2
    , x_approval_rules_id out nocopy  NUMBER
  )

  as
    ddp_approval_rules_rec ahl_approvals_pvt.approval_rules_rec_type;
    ddindx binary_integer; indx binary_integer;
  begin

    -- copy data to the local IN or IN-OUT args, if any







    ddp_approval_rules_rec.approval_rule_id := p7_a0;
    ddp_approval_rules_rec.object_version_number := p7_a1;
    ddp_approval_rules_rec.approval_object_code := p7_a2;
    ddp_approval_rules_rec.approval_priority_code := p7_a3;
    ddp_approval_rules_rec.approval_type_code := p7_a4;
    ddp_approval_rules_rec.application_usg_code := p7_a5;
    ddp_approval_rules_rec.application_usg := p7_a6;
    ddp_approval_rules_rec.operating_unit_id := p7_a7;
    ddp_approval_rules_rec.operating_name := p7_a8;
    ddp_approval_rules_rec.active_start_date := rosetta_g_miss_date_in_map(p7_a9);
    ddp_approval_rules_rec.active_end_date := rosetta_g_miss_date_in_map(p7_a10);
    ddp_approval_rules_rec.status_code := p7_a11;
    ddp_approval_rules_rec.seeded_flag := p7_a12;
    ddp_approval_rules_rec.attribute_category := p7_a13;
    ddp_approval_rules_rec.attribute1 := p7_a14;
    ddp_approval_rules_rec.attribute2 := p7_a15;
    ddp_approval_rules_rec.attribute3 := p7_a16;
    ddp_approval_rules_rec.attribute4 := p7_a17;
    ddp_approval_rules_rec.attribute5 := p7_a18;
    ddp_approval_rules_rec.attribute6 := p7_a19;
    ddp_approval_rules_rec.attribute7 := p7_a20;
    ddp_approval_rules_rec.attribute8 := p7_a21;
    ddp_approval_rules_rec.attribute9 := p7_a22;
    ddp_approval_rules_rec.attribute10 := p7_a23;
    ddp_approval_rules_rec.attribute11 := p7_a24;
    ddp_approval_rules_rec.attribute12 := p7_a25;
    ddp_approval_rules_rec.attribute13 := p7_a26;
    ddp_approval_rules_rec.attribute14 := p7_a27;
    ddp_approval_rules_rec.attribute15 := p7_a28;
    ddp_approval_rules_rec.approval_rule_name := p7_a29;
    ddp_approval_rules_rec.description := p7_a30;
    ddp_approval_rules_rec.creation_date := rosetta_g_miss_date_in_map(p7_a31);
    ddp_approval_rules_rec.created_by := p7_a32;
    ddp_approval_rules_rec.last_update_date := rosetta_g_miss_date_in_map(p7_a33);
    ddp_approval_rules_rec.last_updated_by := p7_a34;
    ddp_approval_rules_rec.last_update_login := p7_a35;
    ddp_approval_rules_rec.operation_flag := p7_a36;
    ddp_approval_rules_rec.program_type_code := p7_a37;
    ddp_approval_rules_rec.program_subtype_code := p7_a38;
    ddp_approval_rules_rec.revision_type_code := p7_a39;


    -- here's the delegated call to the old PL/SQL routine
    ahl_approvals_pvt.create_approval_rules(p_api_version,
      p_init_msg_list,
      p_commit,
      p_validation_level,
      x_return_status,
      x_msg_count,
      x_msg_data,
      ddp_approval_rules_rec,
      x_approval_rules_id);

    -- copy data back from the local variables to OUT or IN-OUT args, if any








  end;

  procedure update_approval_rules(p_api_version  NUMBER
    , p_init_msg_list  VARCHAR2
    , p_commit  VARCHAR2
    , p_validation_level  NUMBER
    , x_return_status out nocopy  VARCHAR2
    , x_msg_count out nocopy  NUMBER
    , x_msg_data out nocopy  VARCHAR2
    , p7_a0  NUMBER
    , p7_a1  NUMBER
    , p7_a2  VARCHAR2
    , p7_a3  VARCHAR2
    , p7_a4  VARCHAR2
    , p7_a5  VARCHAR2
    , p7_a6  VARCHAR2
    , p7_a7  NUMBER
    , p7_a8  VARCHAR2
    , p7_a9  DATE
    , p7_a10  DATE
    , p7_a11  VARCHAR2
    , p7_a12  VARCHAR2
    , p7_a13  VARCHAR2
    , p7_a14  VARCHAR2
    , p7_a15  VARCHAR2
    , p7_a16  VARCHAR2
    , p7_a17  VARCHAR2
    , p7_a18  VARCHAR2
    , p7_a19  VARCHAR2
    , p7_a20  VARCHAR2
    , p7_a21  VARCHAR2
    , p7_a22  VARCHAR2
    , p7_a23  VARCHAR2
    , p7_a24  VARCHAR2
    , p7_a25  VARCHAR2
    , p7_a26  VARCHAR2
    , p7_a27  VARCHAR2
    , p7_a28  VARCHAR2
    , p7_a29  VARCHAR2
    , p7_a30  VARCHAR2
    , p7_a31  DATE
    , p7_a32  NUMBER
    , p7_a33  DATE
    , p7_a34  NUMBER
    , p7_a35  NUMBER
    , p7_a36  VARCHAR2
    , p7_a37  VARCHAR2
    , p7_a38  VARCHAR2
    , p7_a39  VARCHAR2
  )

  as
    ddp_approval_rules_rec ahl_approvals_pvt.approval_rules_rec_type;
    ddindx binary_integer; indx binary_integer;
  begin

    -- copy data to the local IN or IN-OUT args, if any







    ddp_approval_rules_rec.approval_rule_id := p7_a0;
    ddp_approval_rules_rec.object_version_number := p7_a1;
    ddp_approval_rules_rec.approval_object_code := p7_a2;
    ddp_approval_rules_rec.approval_priority_code := p7_a3;
    ddp_approval_rules_rec.approval_type_code := p7_a4;
    ddp_approval_rules_rec.application_usg_code := p7_a5;
    ddp_approval_rules_rec.application_usg := p7_a6;
    ddp_approval_rules_rec.operating_unit_id := p7_a7;
    ddp_approval_rules_rec.operating_name := p7_a8;
    ddp_approval_rules_rec.active_start_date := rosetta_g_miss_date_in_map(p7_a9);
    ddp_approval_rules_rec.active_end_date := rosetta_g_miss_date_in_map(p7_a10);
    ddp_approval_rules_rec.status_code := p7_a11;
    ddp_approval_rules_rec.seeded_flag := p7_a12;
    ddp_approval_rules_rec.attribute_category := p7_a13;
    ddp_approval_rules_rec.attribute1 := p7_a14;
    ddp_approval_rules_rec.attribute2 := p7_a15;
    ddp_approval_rules_rec.attribute3 := p7_a16;
    ddp_approval_rules_rec.attribute4 := p7_a17;
    ddp_approval_rules_rec.attribute5 := p7_a18;
    ddp_approval_rules_rec.attribute6 := p7_a19;
    ddp_approval_rules_rec.attribute7 := p7_a20;
    ddp_approval_rules_rec.attribute8 := p7_a21;
    ddp_approval_rules_rec.attribute9 := p7_a22;
    ddp_approval_rules_rec.attribute10 := p7_a23;
    ddp_approval_rules_rec.attribute11 := p7_a24;
    ddp_approval_rules_rec.attribute12 := p7_a25;
    ddp_approval_rules_rec.attribute13 := p7_a26;
    ddp_approval_rules_rec.attribute14 := p7_a27;
    ddp_approval_rules_rec.attribute15 := p7_a28;
    ddp_approval_rules_rec.approval_rule_name := p7_a29;
    ddp_approval_rules_rec.description := p7_a30;
    ddp_approval_rules_rec.creation_date := rosetta_g_miss_date_in_map(p7_a31);
    ddp_approval_rules_rec.created_by := p7_a32;
    ddp_approval_rules_rec.last_update_date := rosetta_g_miss_date_in_map(p7_a33);
    ddp_approval_rules_rec.last_updated_by := p7_a34;
    ddp_approval_rules_rec.last_update_login := p7_a35;
    ddp_approval_rules_rec.operation_flag := p7_a36;
    ddp_approval_rules_rec.program_type_code := p7_a37;
    ddp_approval_rules_rec.program_subtype_code := p7_a38;
    ddp_approval_rules_rec.revision_type_code := p7_a39;

    -- here's the delegated call to the old PL/SQL routine
    ahl_approvals_pvt.update_approval_rules(p_api_version,
      p_init_msg_list,
      p_commit,
      p_validation_level,
      x_return_status,
      x_msg_count,
      x_msg_data,
      ddp_approval_rules_rec);

    -- copy data back from the local variables to OUT or IN-OUT args, if any







  end;

  procedure validate_approval_rules(p_api_version  NUMBER
    , p_init_msg_list  VARCHAR2
    , p_commit  VARCHAR2
    , p_validation_level  NUMBER
    , x_return_status out nocopy  VARCHAR2
    , x_msg_count out nocopy  NUMBER
    , x_msg_data out nocopy  VARCHAR2
    , p7_a0  NUMBER
    , p7_a1  NUMBER
    , p7_a2  VARCHAR2
    , p7_a3  VARCHAR2
    , p7_a4  VARCHAR2
    , p7_a5  VARCHAR2
    , p7_a6  VARCHAR2
    , p7_a7  NUMBER
    , p7_a8  VARCHAR2
    , p7_a9  DATE
    , p7_a10  DATE
    , p7_a11  VARCHAR2
    , p7_a12  VARCHAR2
    , p7_a13  VARCHAR2
    , p7_a14  VARCHAR2
    , p7_a15  VARCHAR2
    , p7_a16  VARCHAR2
    , p7_a17  VARCHAR2
    , p7_a18  VARCHAR2
    , p7_a19  VARCHAR2
    , p7_a20  VARCHAR2
    , p7_a21  VARCHAR2
    , p7_a22  VARCHAR2
    , p7_a23  VARCHAR2
    , p7_a24  VARCHAR2
    , p7_a25  VARCHAR2
    , p7_a26  VARCHAR2
    , p7_a27  VARCHAR2
    , p7_a28  VARCHAR2
    , p7_a29  VARCHAR2
    , p7_a30  VARCHAR2
    , p7_a31  DATE
    , p7_a32  NUMBER
    , p7_a33  DATE
    , p7_a34  NUMBER
    , p7_a35  NUMBER
    , p7_a36  VARCHAR2
    , p7_a37  VARCHAR2
    , p7_a38  VARCHAR2
    , p7_a39  VARCHAR2
  )

  as
    ddp_approval_rules_rec ahl_approvals_pvt.approval_rules_rec_type;
    ddindx binary_integer; indx binary_integer;
  begin

    -- copy data to the local IN or IN-OUT args, if any







    ddp_approval_rules_rec.approval_rule_id := p7_a0;
    ddp_approval_rules_rec.object_version_number := p7_a1;
    ddp_approval_rules_rec.approval_object_code := p7_a2;
    ddp_approval_rules_rec.approval_priority_code := p7_a3;
    ddp_approval_rules_rec.approval_type_code := p7_a4;
    ddp_approval_rules_rec.application_usg_code := p7_a5;
    ddp_approval_rules_rec.application_usg := p7_a6;
    ddp_approval_rules_rec.operating_unit_id := p7_a7;
    ddp_approval_rules_rec.operating_name := p7_a8;
    ddp_approval_rules_rec.active_start_date := rosetta_g_miss_date_in_map(p7_a9);
    ddp_approval_rules_rec.active_end_date := rosetta_g_miss_date_in_map(p7_a10);
    ddp_approval_rules_rec.status_code := p7_a11;
    ddp_approval_rules_rec.seeded_flag := p7_a12;
    ddp_approval_rules_rec.attribute_category := p7_a13;
    ddp_approval_rules_rec.attribute1 := p7_a14;
    ddp_approval_rules_rec.attribute2 := p7_a15;
    ddp_approval_rules_rec.attribute3 := p7_a16;
    ddp_approval_rules_rec.attribute4 := p7_a17;
    ddp_approval_rules_rec.attribute5 := p7_a18;
    ddp_approval_rules_rec.attribute6 := p7_a19;
    ddp_approval_rules_rec.attribute7 := p7_a20;
    ddp_approval_rules_rec.attribute8 := p7_a21;
    ddp_approval_rules_rec.attribute9 := p7_a22;
    ddp_approval_rules_rec.attribute10 := p7_a23;
    ddp_approval_rules_rec.attribute11 := p7_a24;
    ddp_approval_rules_rec.attribute12 := p7_a25;
    ddp_approval_rules_rec.attribute13 := p7_a26;
    ddp_approval_rules_rec.attribute14 := p7_a27;
    ddp_approval_rules_rec.attribute15 := p7_a28;
    ddp_approval_rules_rec.approval_rule_name := p7_a29;
    ddp_approval_rules_rec.description := p7_a30;
    ddp_approval_rules_rec.creation_date := rosetta_g_miss_date_in_map(p7_a31);
    ddp_approval_rules_rec.created_by := p7_a32;
    ddp_approval_rules_rec.last_update_date := rosetta_g_miss_date_in_map(p7_a33);
    ddp_approval_rules_rec.last_updated_by := p7_a34;
    ddp_approval_rules_rec.last_update_login := p7_a35;
    ddp_approval_rules_rec.operation_flag := p7_a36;
    ddp_approval_rules_rec.program_type_code := p7_a37;
    ddp_approval_rules_rec.program_subtype_code := p7_a38;
    ddp_approval_rules_rec.revision_type_code := p7_a39;

    -- here's the delegated call to the old PL/SQL routine
    ahl_approvals_pvt.validate_approval_rules(p_api_version,
      p_init_msg_list,
      p_commit,
      p_validation_level,
      x_return_status,
      x_msg_count,
      x_msg_data,
      ddp_approval_rules_rec);

    -- copy data back from the local variables to OUT or IN-OUT args, if any







  end;

  procedure check_approval_rules_items(p0_a0  NUMBER
    , p0_a1  NUMBER
    , p0_a2  VARCHAR2
    , p0_a3  VARCHAR2
    , p0_a4  VARCHAR2
    , p0_a5  VARCHAR2
    , p0_a6  VARCHAR2
    , p0_a7  NUMBER
    , p0_a8  VARCHAR2
    , p0_a9  DATE
    , p0_a10  DATE
    , p0_a11  VARCHAR2
    , p0_a12  VARCHAR2
    , p0_a13  VARCHAR2
    , p0_a14  VARCHAR2
    , p0_a15  VARCHAR2
    , p0_a16  VARCHAR2
    , p0_a17  VARCHAR2
    , p0_a18  VARCHAR2
    , p0_a19  VARCHAR2
    , p0_a20  VARCHAR2
    , p0_a21  VARCHAR2
    , p0_a22  VARCHAR2
    , p0_a23  VARCHAR2
    , p0_a24  VARCHAR2
    , p0_a25  VARCHAR2
    , p0_a26  VARCHAR2
    , p0_a27  VARCHAR2
    , p0_a28  VARCHAR2
    , p0_a29  VARCHAR2
    , p0_a30  VARCHAR2
    , p0_a31  DATE
    , p0_a32  NUMBER
    , p0_a33  DATE
    , p0_a34  NUMBER
    , p0_a35  NUMBER
    , p0_a36  VARCHAR2
    , p0_a37  VARCHAR2
    , p0_a38  VARCHAR2
    , p0_a39  VARCHAR2
    , p_validation_mode  VARCHAR2
    , x_return_status out nocopy  VARCHAR2
  )

  as
    ddp_approval_rules_rec ahl_approvals_pvt.approval_rules_rec_type;
    ddindx binary_integer; indx binary_integer;
  begin

    -- copy data to the local IN or IN-OUT args, if any
    ddp_approval_rules_rec.approval_rule_id := p0_a0;
    ddp_approval_rules_rec.object_version_number := p0_a1;
    ddp_approval_rules_rec.approval_object_code := p0_a2;
    ddp_approval_rules_rec.approval_priority_code := p0_a3;
    ddp_approval_rules_rec.approval_type_code := p0_a4;
    ddp_approval_rules_rec.application_usg_code := p0_a5;
    ddp_approval_rules_rec.application_usg := p0_a6;
    ddp_approval_rules_rec.operating_unit_id := p0_a7;
    ddp_approval_rules_rec.operating_name := p0_a8;
    ddp_approval_rules_rec.active_start_date := rosetta_g_miss_date_in_map(p0_a9);
    ddp_approval_rules_rec.active_end_date := rosetta_g_miss_date_in_map(p0_a10);
    ddp_approval_rules_rec.status_code := p0_a11;
    ddp_approval_rules_rec.seeded_flag := p0_a12;
    ddp_approval_rules_rec.attribute_category := p0_a13;
    ddp_approval_rules_rec.attribute1 := p0_a14;
    ddp_approval_rules_rec.attribute2 := p0_a15;
    ddp_approval_rules_rec.attribute3 := p0_a16;
    ddp_approval_rules_rec.attribute4 := p0_a17;
    ddp_approval_rules_rec.attribute5 := p0_a18;
    ddp_approval_rules_rec.attribute6 := p0_a19;
    ddp_approval_rules_rec.attribute7 := p0_a20;
    ddp_approval_rules_rec.attribute8 := p0_a21;
    ddp_approval_rules_rec.attribute9 := p0_a22;
    ddp_approval_rules_rec.attribute10 := p0_a23;
    ddp_approval_rules_rec.attribute11 := p0_a24;
    ddp_approval_rules_rec.attribute12 := p0_a25;
    ddp_approval_rules_rec.attribute13 := p0_a26;
    ddp_approval_rules_rec.attribute14 := p0_a27;
    ddp_approval_rules_rec.attribute15 := p0_a28;
    ddp_approval_rules_rec.approval_rule_name := p0_a29;
    ddp_approval_rules_rec.description := p0_a30;
    ddp_approval_rules_rec.creation_date := rosetta_g_miss_date_in_map(p0_a31);
    ddp_approval_rules_rec.created_by := p0_a32;
    ddp_approval_rules_rec.last_update_date := rosetta_g_miss_date_in_map(p0_a33);
    ddp_approval_rules_rec.last_updated_by := p0_a34;
    ddp_approval_rules_rec.last_update_login := p0_a35;
    ddp_approval_rules_rec.operation_flag := p0_a36;
    ddp_approval_rules_rec.program_type_code := p0_a37;
    ddp_approval_rules_rec.program_subtype_code := p0_a38;
    ddp_approval_rules_rec.revision_type_code := p0_a39;



    -- here's the delegated call to the old PL/SQL routine
    ahl_approvals_pvt.check_approval_rules_items(ddp_approval_rules_rec,
      p_validation_mode,
      x_return_status);

    -- copy data back from the local variables to OUT or IN-OUT args, if any


  end;

  procedure check_approval_rules_record(p0_a0  NUMBER
    , p0_a1  NUMBER
    , p0_a2  VARCHAR2
    , p0_a3  VARCHAR2
    , p0_a4  VARCHAR2
    , p0_a5  VARCHAR2
    , p0_a6  VARCHAR2
    , p0_a7  NUMBER
    , p0_a8  VARCHAR2
    , p0_a9  DATE
    , p0_a10  DATE
    , p0_a11  VARCHAR2
    , p0_a12  VARCHAR2
    , p0_a13  VARCHAR2
    , p0_a14  VARCHAR2
    , p0_a15  VARCHAR2
    , p0_a16  VARCHAR2
    , p0_a17  VARCHAR2
    , p0_a18  VARCHAR2
    , p0_a19  VARCHAR2
    , p0_a20  VARCHAR2
    , p0_a21  VARCHAR2
    , p0_a22  VARCHAR2
    , p0_a23  VARCHAR2
    , p0_a24  VARCHAR2
    , p0_a25  VARCHAR2
    , p0_a26  VARCHAR2
    , p0_a27  VARCHAR2
    , p0_a28  VARCHAR2
    , p0_a29  VARCHAR2
    , p0_a30  VARCHAR2
    , p0_a31  DATE
    , p0_a32  NUMBER
    , p0_a33  DATE
    , p0_a34  NUMBER
    , p0_a35  NUMBER
    , p0_a36  VARCHAR2
    , p0_a37  VARCHAR2
    , p0_a38  VARCHAR2
    , p0_a39  VARCHAR2
    , p1_a0  NUMBER
    , p1_a1  NUMBER
    , p1_a2  VARCHAR2
    , p1_a3  VARCHAR2
    , p1_a4  VARCHAR2
    , p1_a5  VARCHAR2
    , p1_a6  VARCHAR2
    , p1_a7  NUMBER
    , p1_a8  VARCHAR2
    , p1_a9  DATE
    , p1_a10  DATE
    , p1_a11  VARCHAR2
    , p1_a12  VARCHAR2
    , p1_a13  VARCHAR2
    , p1_a14  VARCHAR2
    , p1_a15  VARCHAR2
    , p1_a16  VARCHAR2
    , p1_a17  VARCHAR2
    , p1_a18  VARCHAR2
    , p1_a19  VARCHAR2
    , p1_a20  VARCHAR2
    , p1_a21  VARCHAR2
    , p1_a22  VARCHAR2
    , p1_a23  VARCHAR2
    , p1_a24  VARCHAR2
    , p1_a25  VARCHAR2
    , p1_a26  VARCHAR2
    , p1_a27  VARCHAR2
    , p1_a28  VARCHAR2
    , p1_a29  VARCHAR2
    , p1_a30  VARCHAR2
    , p1_a31  DATE
    , p1_a32  NUMBER
    , p1_a33  DATE
    , p1_a34  NUMBER
    , p1_a35  NUMBER
    , p1_a36  VARCHAR2
    , p1_a37  VARCHAR2
    , p1_a38  VARCHAR2
    , p1_a39  VARCHAR2
    , x_return_status out nocopy  VARCHAR2
  )

  as
    ddp_approval_rules_rec ahl_approvals_pvt.approval_rules_rec_type;
    ddp_complete_rec ahl_approvals_pvt.approval_rules_rec_type;
    ddindx binary_integer; indx binary_integer;
  begin

    -- copy data to the local IN or IN-OUT args, if any
    ddp_approval_rules_rec.approval_rule_id := p0_a0;
    ddp_approval_rules_rec.object_version_number := p0_a1;
    ddp_approval_rules_rec.approval_object_code := p0_a2;
    ddp_approval_rules_rec.approval_priority_code := p0_a3;
    ddp_approval_rules_rec.approval_type_code := p0_a4;
    ddp_approval_rules_rec.application_usg_code := p0_a5;
    ddp_approval_rules_rec.application_usg := p0_a6;
    ddp_approval_rules_rec.operating_unit_id := p0_a7;
    ddp_approval_rules_rec.operating_name := p0_a8;
    ddp_approval_rules_rec.active_start_date := rosetta_g_miss_date_in_map(p0_a9);
    ddp_approval_rules_rec.active_end_date := rosetta_g_miss_date_in_map(p0_a10);
    ddp_approval_rules_rec.status_code := p0_a11;
    ddp_approval_rules_rec.seeded_flag := p0_a12;
    ddp_approval_rules_rec.attribute_category := p0_a13;
    ddp_approval_rules_rec.attribute1 := p0_a14;
    ddp_approval_rules_rec.attribute2 := p0_a15;
    ddp_approval_rules_rec.attribute3 := p0_a16;
    ddp_approval_rules_rec.attribute4 := p0_a17;
    ddp_approval_rules_rec.attribute5 := p0_a18;
    ddp_approval_rules_rec.attribute6 := p0_a19;
    ddp_approval_rules_rec.attribute7 := p0_a20;
    ddp_approval_rules_rec.attribute8 := p0_a21;
    ddp_approval_rules_rec.attribute9 := p0_a22;
    ddp_approval_rules_rec.attribute10 := p0_a23;
    ddp_approval_rules_rec.attribute11 := p0_a24;
    ddp_approval_rules_rec.attribute12 := p0_a25;
    ddp_approval_rules_rec.attribute13 := p0_a26;
    ddp_approval_rules_rec.attribute14 := p0_a27;
    ddp_approval_rules_rec.attribute15 := p0_a28;
    ddp_approval_rules_rec.approval_rule_name := p0_a29;
    ddp_approval_rules_rec.description := p0_a30;
    ddp_approval_rules_rec.creation_date := rosetta_g_miss_date_in_map(p0_a31);
    ddp_approval_rules_rec.created_by := p0_a32;
    ddp_approval_rules_rec.last_update_date := rosetta_g_miss_date_in_map(p0_a33);
    ddp_approval_rules_rec.last_updated_by := p0_a34;
    ddp_approval_rules_rec.last_update_login := p0_a35;
    ddp_approval_rules_rec.operation_flag := p0_a36;
    ddp_approval_rules_rec.program_type_code := p0_a37;
    ddp_approval_rules_rec.program_subtype_code := p0_a38;
    ddp_approval_rules_rec.revision_type_code := p0_a39;

    ddp_complete_rec.approval_rule_id := p1_a0;
    ddp_complete_rec.object_version_number := p1_a1;
    ddp_complete_rec.approval_object_code := p1_a2;
    ddp_complete_rec.approval_priority_code := p1_a3;
    ddp_complete_rec.approval_type_code := p1_a4;
    ddp_complete_rec.application_usg_code := p1_a5;
    ddp_complete_rec.application_usg := p1_a6;
    ddp_complete_rec.operating_unit_id := p1_a7;
    ddp_complete_rec.operating_name := p1_a8;
    ddp_complete_rec.active_start_date := rosetta_g_miss_date_in_map(p1_a9);
    ddp_complete_rec.active_end_date := rosetta_g_miss_date_in_map(p1_a10);
    ddp_complete_rec.status_code := p1_a11;
    ddp_complete_rec.seeded_flag := p1_a12;
    ddp_complete_rec.attribute_category := p1_a13;
    ddp_complete_rec.attribute1 := p1_a14;
    ddp_complete_rec.attribute2 := p1_a15;
    ddp_complete_rec.attribute3 := p1_a16;
    ddp_complete_rec.attribute4 := p1_a17;
    ddp_complete_rec.attribute5 := p1_a18;
    ddp_complete_rec.attribute6 := p1_a19;
    ddp_complete_rec.attribute7 := p1_a20;
    ddp_complete_rec.attribute8 := p1_a21;
    ddp_complete_rec.attribute9 := p1_a22;
    ddp_complete_rec.attribute10 := p1_a23;
    ddp_complete_rec.attribute11 := p1_a24;
    ddp_complete_rec.attribute12 := p1_a25;
    ddp_complete_rec.attribute13 := p1_a26;
    ddp_complete_rec.attribute14 := p1_a27;
    ddp_complete_rec.attribute15 := p1_a28;
    ddp_complete_rec.approval_rule_name := p1_a29;
    ddp_complete_rec.description := p1_a30;
    ddp_complete_rec.creation_date := rosetta_g_miss_date_in_map(p1_a31);
    ddp_complete_rec.created_by := p1_a32;
    ddp_complete_rec.last_update_date := rosetta_g_miss_date_in_map(p1_a33);
    ddp_complete_rec.last_updated_by := p1_a34;
    ddp_complete_rec.last_update_login := p1_a35;
    ddp_complete_rec.operation_flag := p1_a36;
    ddp_complete_rec.program_type_code := p1_a37;
    ddp_complete_rec.program_subtype_code := p1_a38;
    ddp_complete_rec.revision_type_code := p1_a39;


    -- here's the delegated call to the old PL/SQL routine
    ahl_approvals_pvt.check_approval_rules_record(ddp_approval_rules_rec,
      ddp_complete_rec,
      x_return_status);

    -- copy data back from the local variables to OUT or IN-OUT args, if any


  end;

  procedure complete_approval_rules_rec(p0_a0  NUMBER
    , p0_a1  NUMBER
    , p0_a2  VARCHAR2
    , p0_a3  VARCHAR2
    , p0_a4  VARCHAR2
    , p0_a5  VARCHAR2
    , p0_a6  VARCHAR2
    , p0_a7  NUMBER
    , p0_a8  VARCHAR2
    , p0_a9  DATE
    , p0_a10  DATE
    , p0_a11  VARCHAR2
    , p0_a12  VARCHAR2
    , p0_a13  VARCHAR2
    , p0_a14  VARCHAR2
    , p0_a15  VARCHAR2
    , p0_a16  VARCHAR2
    , p0_a17  VARCHAR2
    , p0_a18  VARCHAR2
    , p0_a19  VARCHAR2
    , p0_a20  VARCHAR2
    , p0_a21  VARCHAR2
    , p0_a22  VARCHAR2
    , p0_a23  VARCHAR2
    , p0_a24  VARCHAR2
    , p0_a25  VARCHAR2
    , p0_a26  VARCHAR2
    , p0_a27  VARCHAR2
    , p0_a28  VARCHAR2
    , p0_a29  VARCHAR2
    , p0_a30  VARCHAR2
    , p0_a31  DATE
    , p0_a32  NUMBER
    , p0_a33  DATE
    , p0_a34  NUMBER
    , p0_a35  NUMBER
    , p0_a36  VARCHAR2
    , p0_a37  VARCHAR2
    , p0_a38  VARCHAR2
    , p0_a39  VARCHAR2
    , p1_a0 out nocopy  NUMBER
    , p1_a1 out nocopy  NUMBER
    , p1_a2 out nocopy  VARCHAR2
    , p1_a3 out nocopy  VARCHAR2
    , p1_a4 out nocopy  VARCHAR2
    , p1_a5 out nocopy  VARCHAR2
    , p1_a6 out nocopy  VARCHAR2
    , p1_a7 out nocopy  NUMBER
    , p1_a8 out nocopy  VARCHAR2
    , p1_a9 out nocopy  DATE
    , p1_a10 out nocopy  DATE
    , p1_a11 out nocopy  VARCHAR2
    , p1_a12 out nocopy  VARCHAR2
    , p1_a13 out nocopy  VARCHAR2
    , p1_a14 out nocopy  VARCHAR2
    , p1_a15 out nocopy  VARCHAR2
    , p1_a16 out nocopy  VARCHAR2
    , p1_a17 out nocopy  VARCHAR2
    , p1_a18 out nocopy  VARCHAR2
    , p1_a19 out nocopy  VARCHAR2
    , p1_a20 out nocopy  VARCHAR2
    , p1_a21 out nocopy  VARCHAR2
    , p1_a22 out nocopy  VARCHAR2
    , p1_a23 out nocopy  VARCHAR2
    , p1_a24 out nocopy  VARCHAR2
    , p1_a25 out nocopy  VARCHAR2
    , p1_a26 out nocopy  VARCHAR2
    , p1_a27 out nocopy  VARCHAR2
    , p1_a28 out nocopy  VARCHAR2
    , p1_a29 out nocopy  VARCHAR2
    , p1_a30 out nocopy  VARCHAR2
    , p1_a31 out nocopy  DATE
    , p1_a32 out nocopy  NUMBER
    , p1_a33 out nocopy  DATE
    , p1_a34 out nocopy  NUMBER
    , p1_a35 out nocopy  NUMBER
    , p1_a36 out nocopy  VARCHAR2
    , p1_a37 out nocopy  VARCHAR2
    , p1_a38 out nocopy  VARCHAR2
    , p1_a39 out nocopy  VARCHAR2
  )

  as
    ddp_approval_rules_rec ahl_approvals_pvt.approval_rules_rec_type;
    ddx_complete_rec ahl_approvals_pvt.approval_rules_rec_type;
    ddindx binary_integer; indx binary_integer;
  begin

    -- copy data to the local IN or IN-OUT args, if any
    ddp_approval_rules_rec.approval_rule_id := p0_a0;
    ddp_approval_rules_rec.object_version_number := p0_a1;
    ddp_approval_rules_rec.approval_object_code := p0_a2;
    ddp_approval_rules_rec.approval_priority_code := p0_a3;
    ddp_approval_rules_rec.approval_type_code := p0_a4;
    ddp_approval_rules_rec.application_usg_code := p0_a5;
    ddp_approval_rules_rec.application_usg := p0_a6;
    ddp_approval_rules_rec.operating_unit_id := p0_a7;
    ddp_approval_rules_rec.operating_name := p0_a8;
    ddp_approval_rules_rec.active_start_date := rosetta_g_miss_date_in_map(p0_a9);
    ddp_approval_rules_rec.active_end_date := rosetta_g_miss_date_in_map(p0_a10);
    ddp_approval_rules_rec.status_code := p0_a11;
    ddp_approval_rules_rec.seeded_flag := p0_a12;
    ddp_approval_rules_rec.attribute_category := p0_a13;
    ddp_approval_rules_rec.attribute1 := p0_a14;
    ddp_approval_rules_rec.attribute2 := p0_a15;
    ddp_approval_rules_rec.attribute3 := p0_a16;
    ddp_approval_rules_rec.attribute4 := p0_a17;
    ddp_approval_rules_rec.attribute5 := p0_a18;
    ddp_approval_rules_rec.attribute6 := p0_a19;
    ddp_approval_rules_rec.attribute7 := p0_a20;
    ddp_approval_rules_rec.attribute8 := p0_a21;
    ddp_approval_rules_rec.attribute9 := p0_a22;
    ddp_approval_rules_rec.attribute10 := p0_a23;
    ddp_approval_rules_rec.attribute11 := p0_a24;
    ddp_approval_rules_rec.attribute12 := p0_a25;
    ddp_approval_rules_rec.attribute13 := p0_a26;
    ddp_approval_rules_rec.attribute14 := p0_a27;
    ddp_approval_rules_rec.attribute15 := p0_a28;
    ddp_approval_rules_rec.approval_rule_name := p0_a29;
    ddp_approval_rules_rec.description := p0_a30;
    ddp_approval_rules_rec.creation_date := rosetta_g_miss_date_in_map(p0_a31);
    ddp_approval_rules_rec.created_by := p0_a32;
    ddp_approval_rules_rec.last_update_date := rosetta_g_miss_date_in_map(p0_a33);
    ddp_approval_rules_rec.last_updated_by := p0_a34;
    ddp_approval_rules_rec.last_update_login := p0_a35;
    ddp_approval_rules_rec.operation_flag := p0_a36;
    ddp_approval_rules_rec.program_type_code := p0_a37;
    ddp_approval_rules_rec.program_subtype_code := p0_a38;
    ddp_approval_rules_rec.revision_type_code := p0_a39;


    -- here's the delegated call to the old PL/SQL routine
    ahl_approvals_pvt.complete_approval_rules_rec(ddp_approval_rules_rec,
      ddx_complete_rec);

    -- copy data back from the local variables to OUT or IN-OUT args, if any

    p1_a0 := ddx_complete_rec.approval_rule_id;
    p1_a1 := ddx_complete_rec.object_version_number;
    p1_a2 := ddx_complete_rec.approval_object_code;
    p1_a3 := ddx_complete_rec.approval_priority_code;
    p1_a4 := ddx_complete_rec.approval_type_code;
    p1_a5 := ddx_complete_rec.application_usg_code;
    p1_a6 := ddx_complete_rec.application_usg;
    p1_a7 := ddx_complete_rec.operating_unit_id;
    p1_a8 := ddx_complete_rec.operating_name;
    p1_a9 := ddx_complete_rec.active_start_date;
    p1_a10 := ddx_complete_rec.active_end_date;
    p1_a11 := ddx_complete_rec.status_code;
    p1_a12 := ddx_complete_rec.seeded_flag;
    p1_a13 := ddx_complete_rec.attribute_category;
    p1_a14 := ddx_complete_rec.attribute1;
    p1_a15 := ddx_complete_rec.attribute2;
    p1_a16 := ddx_complete_rec.attribute3;
    p1_a17 := ddx_complete_rec.attribute4;
    p1_a18 := ddx_complete_rec.attribute5;
    p1_a19 := ddx_complete_rec.attribute6;
    p1_a20 := ddx_complete_rec.attribute7;
    p1_a21 := ddx_complete_rec.attribute8;
    p1_a22 := ddx_complete_rec.attribute9;
    p1_a23 := ddx_complete_rec.attribute10;
    p1_a24 := ddx_complete_rec.attribute11;
    p1_a25 := ddx_complete_rec.attribute12;
    p1_a26 := ddx_complete_rec.attribute13;
    p1_a27 := ddx_complete_rec.attribute14;
    p1_a28 := ddx_complete_rec.attribute15;
    p1_a29 := ddx_complete_rec.approval_rule_name;
    p1_a30 := ddx_complete_rec.description;
    p1_a31 := ddx_complete_rec.creation_date;
    p1_a32 := ddx_complete_rec.created_by;
    p1_a33 := ddx_complete_rec.last_update_date;
    p1_a34 := ddx_complete_rec.last_updated_by;
    p1_a35 := ddx_complete_rec.last_update_login;
    p1_a36 := ddx_complete_rec.operation_flag;
    p1_a37 := ddx_complete_rec.program_type_code;
    p1_a38 := ddx_complete_rec.program_subtype_code;
    p1_a39 := ddx_complete_rec.revision_type_code;
  end;

  procedure create_approvers(p_api_version  NUMBER
    , p_init_msg_list  VARCHAR2
    , p_commit  VARCHAR2
    , p_validation_level  NUMBER
    , x_return_status out nocopy  VARCHAR2
    , x_msg_count out nocopy  NUMBER
    , x_msg_data out nocopy  VARCHAR2
    , p7_a0  NUMBER
    , p7_a1  NUMBER
    , p7_a2  NUMBER
    , p7_a3  VARCHAR2
    , p7_a4  NUMBER
    , p7_a5  NUMBER
    , p7_a6  VARCHAR2
    , p7_a7  DATE
    , p7_a8  NUMBER
    , p7_a9  DATE
    , p7_a10  NUMBER
    , p7_a11  NUMBER
    , p7_a12  VARCHAR2
    , p7_a13  VARCHAR2
    , p7_a14  VARCHAR2
    , p7_a15  VARCHAR2
    , p7_a16  VARCHAR2
    , p7_a17  VARCHAR2
    , p7_a18  VARCHAR2
    , p7_a19  VARCHAR2
    , p7_a20  VARCHAR2
    , p7_a21  VARCHAR2
    , p7_a22  VARCHAR2
    , p7_a23  VARCHAR2
    , p7_a24  VARCHAR2
    , p7_a25  VARCHAR2
    , p7_a26  VARCHAR2
    , p7_a27  VARCHAR2
    , p7_a28  VARCHAR2
    , x_approval_approver_id out nocopy  NUMBER
  )

  as
    ddp_approvers_rec ahl_approvals_pvt.approvers_rec_type;
    ddindx binary_integer; indx binary_integer;
  begin

    -- copy data to the local IN or IN-OUT args, if any







    ddp_approvers_rec.approval_approver_id := p7_a0;
    ddp_approvers_rec.object_version_number := p7_a1;
    ddp_approvers_rec.approval_rule_id := p7_a2;
    ddp_approvers_rec.approver_type_code := p7_a3;
    ddp_approvers_rec.approver_sequence := p7_a4;
    ddp_approvers_rec.approver_id := p7_a5;
    ddp_approvers_rec.approver_name := p7_a6;
    ddp_approvers_rec.last_update_date := rosetta_g_miss_date_in_map(p7_a7);
    ddp_approvers_rec.last_updated_by := p7_a8;
    ddp_approvers_rec.creation_date := rosetta_g_miss_date_in_map(p7_a9);
    ddp_approvers_rec.created_by := p7_a10;
    ddp_approvers_rec.last_update_login := p7_a11;
    ddp_approvers_rec.attribute_category := p7_a12;
    ddp_approvers_rec.attribute1 := p7_a13;
    ddp_approvers_rec.attribute2 := p7_a14;
    ddp_approvers_rec.attribute3 := p7_a15;
    ddp_approvers_rec.attribute4 := p7_a16;
    ddp_approvers_rec.attribute5 := p7_a17;
    ddp_approvers_rec.attribute6 := p7_a18;
    ddp_approvers_rec.attribute7 := p7_a19;
    ddp_approvers_rec.attribute8 := p7_a20;
    ddp_approvers_rec.attribute9 := p7_a21;
    ddp_approvers_rec.attribute10 := p7_a22;
    ddp_approvers_rec.attribute11 := p7_a23;
    ddp_approvers_rec.attribute12 := p7_a24;
    ddp_approvers_rec.attribute13 := p7_a25;
    ddp_approvers_rec.attribute14 := p7_a26;
    ddp_approvers_rec.attribute15 := p7_a27;
    ddp_approvers_rec.operation_flag := p7_a28;


    -- here's the delegated call to the old PL/SQL routine
    ahl_approvals_pvt.create_approvers(p_api_version,
      p_init_msg_list,
      p_commit,
      p_validation_level,
      x_return_status,
      x_msg_count,
      x_msg_data,
      ddp_approvers_rec,
      x_approval_approver_id);

    -- copy data back from the local variables to OUT or IN-OUT args, if any








  end;

  procedure update_approvers(p_api_version  NUMBER
    , p_init_msg_list  VARCHAR2
    , p_commit  VARCHAR2
    , p_validation_level  NUMBER
    , p4_a0  NUMBER
    , p4_a1  NUMBER
    , p4_a2  NUMBER
    , p4_a3  VARCHAR2
    , p4_a4  NUMBER
    , p4_a5  NUMBER
    , p4_a6  VARCHAR2
    , p4_a7  DATE
    , p4_a8  NUMBER
    , p4_a9  DATE
    , p4_a10  NUMBER
    , p4_a11  NUMBER
    , p4_a12  VARCHAR2
    , p4_a13  VARCHAR2
    , p4_a14  VARCHAR2
    , p4_a15  VARCHAR2
    , p4_a16  VARCHAR2
    , p4_a17  VARCHAR2
    , p4_a18  VARCHAR2
    , p4_a19  VARCHAR2
    , p4_a20  VARCHAR2
    , p4_a21  VARCHAR2
    , p4_a22  VARCHAR2
    , p4_a23  VARCHAR2
    , p4_a24  VARCHAR2
    , p4_a25  VARCHAR2
    , p4_a26  VARCHAR2
    , p4_a27  VARCHAR2
    , p4_a28  VARCHAR2
    , x_return_status out nocopy  VARCHAR2
    , x_msg_count out nocopy  NUMBER
    , x_msg_data out nocopy  VARCHAR2
  )

  as
    ddp_approvers_rec ahl_approvals_pvt.approvers_rec_type;
    ddindx binary_integer; indx binary_integer;
  begin

    -- copy data to the local IN or IN-OUT args, if any




    ddp_approvers_rec.approval_approver_id := p4_a0;
    ddp_approvers_rec.object_version_number := p4_a1;
    ddp_approvers_rec.approval_rule_id := p4_a2;
    ddp_approvers_rec.approver_type_code := p4_a3;
    ddp_approvers_rec.approver_sequence := p4_a4;
    ddp_approvers_rec.approver_id := p4_a5;
    ddp_approvers_rec.approver_name := p4_a6;
    ddp_approvers_rec.last_update_date := rosetta_g_miss_date_in_map(p4_a7);
    ddp_approvers_rec.last_updated_by := p4_a8;
    ddp_approvers_rec.creation_date := rosetta_g_miss_date_in_map(p4_a9);
    ddp_approvers_rec.created_by := p4_a10;
    ddp_approvers_rec.last_update_login := p4_a11;
    ddp_approvers_rec.attribute_category := p4_a12;
    ddp_approvers_rec.attribute1 := p4_a13;
    ddp_approvers_rec.attribute2 := p4_a14;
    ddp_approvers_rec.attribute3 := p4_a15;
    ddp_approvers_rec.attribute4 := p4_a16;
    ddp_approvers_rec.attribute5 := p4_a17;
    ddp_approvers_rec.attribute6 := p4_a18;
    ddp_approvers_rec.attribute7 := p4_a19;
    ddp_approvers_rec.attribute8 := p4_a20;
    ddp_approvers_rec.attribute9 := p4_a21;
    ddp_approvers_rec.attribute10 := p4_a22;
    ddp_approvers_rec.attribute11 := p4_a23;
    ddp_approvers_rec.attribute12 := p4_a24;
    ddp_approvers_rec.attribute13 := p4_a25;
    ddp_approvers_rec.attribute14 := p4_a26;
    ddp_approvers_rec.attribute15 := p4_a27;
    ddp_approvers_rec.operation_flag := p4_a28;




    -- here's the delegated call to the old PL/SQL routine
    ahl_approvals_pvt.update_approvers(p_api_version,
      p_init_msg_list,
      p_commit,
      p_validation_level,
      ddp_approvers_rec,
      x_return_status,
      x_msg_count,
      x_msg_data);

    -- copy data back from the local variables to OUT or IN-OUT args, if any







  end;

  procedure validate_approvers(p_api_version  NUMBER
    , p_init_msg_list  VARCHAR2
    , p_commit  VARCHAR2
    , p_validation_level  NUMBER
    , x_return_status out nocopy  VARCHAR2
    , x_msg_count out nocopy  NUMBER
    , x_msg_data out nocopy  VARCHAR2
    , p7_a0  NUMBER
    , p7_a1  NUMBER
    , p7_a2  NUMBER
    , p7_a3  VARCHAR2
    , p7_a4  NUMBER
    , p7_a5  NUMBER
    , p7_a6  VARCHAR2
    , p7_a7  DATE
    , p7_a8  NUMBER
    , p7_a9  DATE
    , p7_a10  NUMBER
    , p7_a11  NUMBER
    , p7_a12  VARCHAR2
    , p7_a13  VARCHAR2
    , p7_a14  VARCHAR2
    , p7_a15  VARCHAR2
    , p7_a16  VARCHAR2
    , p7_a17  VARCHAR2
    , p7_a18  VARCHAR2
    , p7_a19  VARCHAR2
    , p7_a20  VARCHAR2
    , p7_a21  VARCHAR2
    , p7_a22  VARCHAR2
    , p7_a23  VARCHAR2
    , p7_a24  VARCHAR2
    , p7_a25  VARCHAR2
    , p7_a26  VARCHAR2
    , p7_a27  VARCHAR2
    , p7_a28  VARCHAR2
  )

  as
    ddp_approvers_rec ahl_approvals_pvt.approvers_rec_type;
    ddindx binary_integer; indx binary_integer;
  begin

    -- copy data to the local IN or IN-OUT args, if any







    ddp_approvers_rec.approval_approver_id := p7_a0;
    ddp_approvers_rec.object_version_number := p7_a1;
    ddp_approvers_rec.approval_rule_id := p7_a2;
    ddp_approvers_rec.approver_type_code := p7_a3;
    ddp_approvers_rec.approver_sequence := p7_a4;
    ddp_approvers_rec.approver_id := p7_a5;
    ddp_approvers_rec.approver_name := p7_a6;
    ddp_approvers_rec.last_update_date := rosetta_g_miss_date_in_map(p7_a7);
    ddp_approvers_rec.last_updated_by := p7_a8;
    ddp_approvers_rec.creation_date := rosetta_g_miss_date_in_map(p7_a9);
    ddp_approvers_rec.created_by := p7_a10;
    ddp_approvers_rec.last_update_login := p7_a11;
    ddp_approvers_rec.attribute_category := p7_a12;
    ddp_approvers_rec.attribute1 := p7_a13;
    ddp_approvers_rec.attribute2 := p7_a14;
    ddp_approvers_rec.attribute3 := p7_a15;
    ddp_approvers_rec.attribute4 := p7_a16;
    ddp_approvers_rec.attribute5 := p7_a17;
    ddp_approvers_rec.attribute6 := p7_a18;
    ddp_approvers_rec.attribute7 := p7_a19;
    ddp_approvers_rec.attribute8 := p7_a20;
    ddp_approvers_rec.attribute9 := p7_a21;
    ddp_approvers_rec.attribute10 := p7_a22;
    ddp_approvers_rec.attribute11 := p7_a23;
    ddp_approvers_rec.attribute12 := p7_a24;
    ddp_approvers_rec.attribute13 := p7_a25;
    ddp_approvers_rec.attribute14 := p7_a26;
    ddp_approvers_rec.attribute15 := p7_a27;
    ddp_approvers_rec.operation_flag := p7_a28;

    -- here's the delegated call to the old PL/SQL routine
    ahl_approvals_pvt.validate_approvers(p_api_version,
      p_init_msg_list,
      p_commit,
      p_validation_level,
      x_return_status,
      x_msg_count,
      x_msg_data,
      ddp_approvers_rec);

    -- copy data back from the local variables to OUT or IN-OUT args, if any







  end;

  procedure check_approvers_items(p_validation_mode  VARCHAR2
    , p1_a0  NUMBER
    , p1_a1  NUMBER
    , p1_a2  NUMBER
    , p1_a3  VARCHAR2
    , p1_a4  NUMBER
    , p1_a5  NUMBER
    , p1_a6  VARCHAR2
    , p1_a7  DATE
    , p1_a8  NUMBER
    , p1_a9  DATE
    , p1_a10  NUMBER
    , p1_a11  NUMBER
    , p1_a12  VARCHAR2
    , p1_a13  VARCHAR2
    , p1_a14  VARCHAR2
    , p1_a15  VARCHAR2
    , p1_a16  VARCHAR2
    , p1_a17  VARCHAR2
    , p1_a18  VARCHAR2
    , p1_a19  VARCHAR2
    , p1_a20  VARCHAR2
    , p1_a21  VARCHAR2
    , p1_a22  VARCHAR2
    , p1_a23  VARCHAR2
    , p1_a24  VARCHAR2
    , p1_a25  VARCHAR2
    , p1_a26  VARCHAR2
    , p1_a27  VARCHAR2
    , p1_a28  VARCHAR2
    , x_return_status out nocopy  VARCHAR2
  )

  as
    ddp_approvers_rec ahl_approvals_pvt.approvers_rec_type;
    ddindx binary_integer; indx binary_integer;
  begin

    -- copy data to the local IN or IN-OUT args, if any

    ddp_approvers_rec.approval_approver_id := p1_a0;
    ddp_approvers_rec.object_version_number := p1_a1;
    ddp_approvers_rec.approval_rule_id := p1_a2;
    ddp_approvers_rec.approver_type_code := p1_a3;
    ddp_approvers_rec.approver_sequence := p1_a4;
    ddp_approvers_rec.approver_id := p1_a5;
    ddp_approvers_rec.approver_name := p1_a6;
    ddp_approvers_rec.last_update_date := rosetta_g_miss_date_in_map(p1_a7);
    ddp_approvers_rec.last_updated_by := p1_a8;
    ddp_approvers_rec.creation_date := rosetta_g_miss_date_in_map(p1_a9);
    ddp_approvers_rec.created_by := p1_a10;
    ddp_approvers_rec.last_update_login := p1_a11;
    ddp_approvers_rec.attribute_category := p1_a12;
    ddp_approvers_rec.attribute1 := p1_a13;
    ddp_approvers_rec.attribute2 := p1_a14;
    ddp_approvers_rec.attribute3 := p1_a15;
    ddp_approvers_rec.attribute4 := p1_a16;
    ddp_approvers_rec.attribute5 := p1_a17;
    ddp_approvers_rec.attribute6 := p1_a18;
    ddp_approvers_rec.attribute7 := p1_a19;
    ddp_approvers_rec.attribute8 := p1_a20;
    ddp_approvers_rec.attribute9 := p1_a21;
    ddp_approvers_rec.attribute10 := p1_a22;
    ddp_approvers_rec.attribute11 := p1_a23;
    ddp_approvers_rec.attribute12 := p1_a24;
    ddp_approvers_rec.attribute13 := p1_a25;
    ddp_approvers_rec.attribute14 := p1_a26;
    ddp_approvers_rec.attribute15 := p1_a27;
    ddp_approvers_rec.operation_flag := p1_a28;


    -- here's the delegated call to the old PL/SQL routine
    ahl_approvals_pvt.check_approvers_items(p_validation_mode,
      ddp_approvers_rec,
      x_return_status);

    -- copy data back from the local variables to OUT or IN-OUT args, if any


  end;

  procedure complete_approvers_rec(p0_a0  NUMBER
    , p0_a1  NUMBER
    , p0_a2  NUMBER
    , p0_a3  VARCHAR2
    , p0_a4  NUMBER
    , p0_a5  NUMBER
    , p0_a6  VARCHAR2
    , p0_a7  DATE
    , p0_a8  NUMBER
    , p0_a9  DATE
    , p0_a10  NUMBER
    , p0_a11  NUMBER
    , p0_a12  VARCHAR2
    , p0_a13  VARCHAR2
    , p0_a14  VARCHAR2
    , p0_a15  VARCHAR2
    , p0_a16  VARCHAR2
    , p0_a17  VARCHAR2
    , p0_a18  VARCHAR2
    , p0_a19  VARCHAR2
    , p0_a20  VARCHAR2
    , p0_a21  VARCHAR2
    , p0_a22  VARCHAR2
    , p0_a23  VARCHAR2
    , p0_a24  VARCHAR2
    , p0_a25  VARCHAR2
    , p0_a26  VARCHAR2
    , p0_a27  VARCHAR2
    , p0_a28  VARCHAR2
    , p1_a0 out nocopy  NUMBER
    , p1_a1 out nocopy  NUMBER
    , p1_a2 out nocopy  NUMBER
    , p1_a3 out nocopy  VARCHAR2
    , p1_a4 out nocopy  NUMBER
    , p1_a5 out nocopy  NUMBER
    , p1_a6 out nocopy  VARCHAR2
    , p1_a7 out nocopy  DATE
    , p1_a8 out nocopy  NUMBER
    , p1_a9 out nocopy  DATE
    , p1_a10 out nocopy  NUMBER
    , p1_a11 out nocopy  NUMBER
    , p1_a12 out nocopy  VARCHAR2
    , p1_a13 out nocopy  VARCHAR2
    , p1_a14 out nocopy  VARCHAR2
    , p1_a15 out nocopy  VARCHAR2
    , p1_a16 out nocopy  VARCHAR2
    , p1_a17 out nocopy  VARCHAR2
    , p1_a18 out nocopy  VARCHAR2
    , p1_a19 out nocopy  VARCHAR2
    , p1_a20 out nocopy  VARCHAR2
    , p1_a21 out nocopy  VARCHAR2
    , p1_a22 out nocopy  VARCHAR2
    , p1_a23 out nocopy  VARCHAR2
    , p1_a24 out nocopy  VARCHAR2
    , p1_a25 out nocopy  VARCHAR2
    , p1_a26 out nocopy  VARCHAR2
    , p1_a27 out nocopy  VARCHAR2
    , p1_a28 out nocopy  VARCHAR2
  )

  as
    ddp_approvers_rec ahl_approvals_pvt.approvers_rec_type;
    ddx_complete_rec ahl_approvals_pvt.approvers_rec_type;
    ddindx binary_integer; indx binary_integer;
  begin

    -- copy data to the local IN or IN-OUT args, if any
    ddp_approvers_rec.approval_approver_id := p0_a0;
    ddp_approvers_rec.object_version_number := p0_a1;
    ddp_approvers_rec.approval_rule_id := p0_a2;
    ddp_approvers_rec.approver_type_code := p0_a3;
    ddp_approvers_rec.approver_sequence := p0_a4;
    ddp_approvers_rec.approver_id := p0_a5;
    ddp_approvers_rec.approver_name := p0_a6;
    ddp_approvers_rec.last_update_date := rosetta_g_miss_date_in_map(p0_a7);
    ddp_approvers_rec.last_updated_by := p0_a8;
    ddp_approvers_rec.creation_date := rosetta_g_miss_date_in_map(p0_a9);
    ddp_approvers_rec.created_by := p0_a10;
    ddp_approvers_rec.last_update_login := p0_a11;
    ddp_approvers_rec.attribute_category := p0_a12;
    ddp_approvers_rec.attribute1 := p0_a13;
    ddp_approvers_rec.attribute2 := p0_a14;
    ddp_approvers_rec.attribute3 := p0_a15;
    ddp_approvers_rec.attribute4 := p0_a16;
    ddp_approvers_rec.attribute5 := p0_a17;
    ddp_approvers_rec.attribute6 := p0_a18;
    ddp_approvers_rec.attribute7 := p0_a19;
    ddp_approvers_rec.attribute8 := p0_a20;
    ddp_approvers_rec.attribute9 := p0_a21;
    ddp_approvers_rec.attribute10 := p0_a22;
    ddp_approvers_rec.attribute11 := p0_a23;
    ddp_approvers_rec.attribute12 := p0_a24;
    ddp_approvers_rec.attribute13 := p0_a25;
    ddp_approvers_rec.attribute14 := p0_a26;
    ddp_approvers_rec.attribute15 := p0_a27;
    ddp_approvers_rec.operation_flag := p0_a28;


    -- here's the delegated call to the old PL/SQL routine
    ahl_approvals_pvt.complete_approvers_rec(ddp_approvers_rec,
      ddx_complete_rec);

    -- copy data back from the local variables to OUT or IN-OUT args, if any

    p1_a0 := ddx_complete_rec.approval_approver_id;
    p1_a1 := ddx_complete_rec.object_version_number;
    p1_a2 := ddx_complete_rec.approval_rule_id;
    p1_a3 := ddx_complete_rec.approver_type_code;
    p1_a4 := ddx_complete_rec.approver_sequence;
    p1_a5 := ddx_complete_rec.approver_id;
    p1_a6 := ddx_complete_rec.approver_name;
    p1_a7 := ddx_complete_rec.last_update_date;
    p1_a8 := ddx_complete_rec.last_updated_by;
    p1_a9 := ddx_complete_rec.creation_date;
    p1_a10 := ddx_complete_rec.created_by;
    p1_a11 := ddx_complete_rec.last_update_login;
    p1_a12 := ddx_complete_rec.attribute_category;
    p1_a13 := ddx_complete_rec.attribute1;
    p1_a14 := ddx_complete_rec.attribute2;
    p1_a15 := ddx_complete_rec.attribute3;
    p1_a16 := ddx_complete_rec.attribute4;
    p1_a17 := ddx_complete_rec.attribute5;
    p1_a18 := ddx_complete_rec.attribute6;
    p1_a19 := ddx_complete_rec.attribute7;
    p1_a20 := ddx_complete_rec.attribute8;
    p1_a21 := ddx_complete_rec.attribute9;
    p1_a22 := ddx_complete_rec.attribute10;
    p1_a23 := ddx_complete_rec.attribute11;
    p1_a24 := ddx_complete_rec.attribute12;
    p1_a25 := ddx_complete_rec.attribute13;
    p1_a26 := ddx_complete_rec.attribute14;
    p1_a27 := ddx_complete_rec.attribute15;
    p1_a28 := ddx_complete_rec.operation_flag;
  end;

end ahl_approvals_pvt_w;
