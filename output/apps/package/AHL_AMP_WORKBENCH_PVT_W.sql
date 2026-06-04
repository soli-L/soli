
  CREATE OR REPLACE EDITIONABLE PACKAGE "APPS"."AHL_AMP_WORKBENCH_PVT_W" AUTHID CURRENT_USER as
  /* $Header: AHLWAMPS.pls 120.0.12020000.2 2012/12/11 05:49:14 prakkum noship $ */
  procedure rosetta_table_copy_in_p6(t out nocopy ahl_amp_workbench_pvt.sch_graph_results_tbl, a0 JTF_NUMBER_TABLE
    , a1 JTF_NUMBER_TABLE
    , a2 JTF_VARCHAR2_TABLE_300
    , a3 JTF_NUMBER_TABLE
    , a4 JTF_VARCHAR2_TABLE_100
    , a5 JTF_NUMBER_TABLE
    , a6 JTF_VARCHAR2_TABLE_300
    , a7 JTF_VARCHAR2_TABLE_100
    , a8 JTF_DATE_TABLE
    , a9 JTF_NUMBER_TABLE
    , a10 JTF_VARCHAR2_TABLE_100
    , a11 JTF_DATE_TABLE
    , a12 JTF_NUMBER_TABLE
    , a13 JTF_VARCHAR2_TABLE_100
    , a14 JTF_DATE_TABLE
    , a15 JTF_NUMBER_TABLE
    , a16 JTF_VARCHAR2_TABLE_100
    , a17 JTF_DATE_TABLE
    , a18 JTF_NUMBER_TABLE
    , a19 JTF_VARCHAR2_TABLE_100
    , a20 JTF_DATE_TABLE
    , a21 JTF_NUMBER_TABLE
    , a22 JTF_VARCHAR2_TABLE_100
    , a23 JTF_DATE_TABLE
    , a24 JTF_NUMBER_TABLE
    , a25 JTF_VARCHAR2_TABLE_100
    , a26 JTF_DATE_TABLE
    , a27 JTF_NUMBER_TABLE
    , a28 JTF_VARCHAR2_TABLE_100
    , a29 JTF_DATE_TABLE
    , a30 JTF_NUMBER_TABLE
    , a31 JTF_VARCHAR2_TABLE_100
    , a32 JTF_DATE_TABLE
    , a33 JTF_NUMBER_TABLE
    , a34 JTF_VARCHAR2_TABLE_100
    , a35 JTF_DATE_TABLE
    , a36 JTF_NUMBER_TABLE
    , a37 JTF_VARCHAR2_TABLE_100
    , a38 JTF_DATE_TABLE
    , a39 JTF_NUMBER_TABLE
    , a40 JTF_VARCHAR2_TABLE_100
    , a41 JTF_DATE_TABLE
    , a42 JTF_NUMBER_TABLE
    , a43 JTF_VARCHAR2_TABLE_100
    , a44 JTF_DATE_TABLE
    , a45 JTF_NUMBER_TABLE
    , a46 JTF_VARCHAR2_TABLE_100
    , a47 JTF_DATE_TABLE
    , a48 JTF_NUMBER_TABLE
    , a49 JTF_VARCHAR2_TABLE_100
    , a50 JTF_DATE_TABLE
    , a51 JTF_NUMBER_TABLE
    , a52 JTF_VARCHAR2_TABLE_100
    , a53 JTF_DATE_TABLE
    , a54 JTF_NUMBER_TABLE
    , a55 JTF_VARCHAR2_TABLE_100
    , a56 JTF_DATE_TABLE
    , a57 JTF_NUMBER_TABLE
    , a58 JTF_VARCHAR2_TABLE_100
    , a59 JTF_DATE_TABLE
    , a60 JTF_NUMBER_TABLE
    , a61 JTF_VARCHAR2_TABLE_100
    , a62 JTF_DATE_TABLE
    , a63 JTF_NUMBER_TABLE
    , a64 JTF_VARCHAR2_TABLE_100
    , a65 JTF_DATE_TABLE
    , a66 JTF_NUMBER_TABLE
    , a67 JTF_VARCHAR2_TABLE_100
    , a68 JTF_DATE_TABLE
    , a69 JTF_NUMBER_TABLE
    , a70 JTF_NUMBER_TABLE
    );
  procedure rosetta_table_copy_out_p6(t ahl_amp_workbench_pvt.sch_graph_results_tbl, a0 out nocopy JTF_NUMBER_TABLE
    , a1 out nocopy JTF_NUMBER_TABLE
    , a2 out nocopy JTF_VARCHAR2_TABLE_300
    , a3 out nocopy JTF_NUMBER_TABLE
    , a4 out nocopy JTF_VARCHAR2_TABLE_100
    , a5 out nocopy JTF_NUMBER_TABLE
    , a6 out nocopy JTF_VARCHAR2_TABLE_300
    , a7 out nocopy JTF_VARCHAR2_TABLE_100
    , a8 out nocopy JTF_DATE_TABLE
    , a9 out nocopy JTF_NUMBER_TABLE
    , a10 out nocopy JTF_VARCHAR2_TABLE_100
    , a11 out nocopy JTF_DATE_TABLE
    , a12 out nocopy JTF_NUMBER_TABLE
    , a13 out nocopy JTF_VARCHAR2_TABLE_100
    , a14 out nocopy JTF_DATE_TABLE
    , a15 out nocopy JTF_NUMBER_TABLE
    , a16 out nocopy JTF_VARCHAR2_TABLE_100
    , a17 out nocopy JTF_DATE_TABLE
    , a18 out nocopy JTF_NUMBER_TABLE
    , a19 out nocopy JTF_VARCHAR2_TABLE_100
    , a20 out nocopy JTF_DATE_TABLE
    , a21 out nocopy JTF_NUMBER_TABLE
    , a22 out nocopy JTF_VARCHAR2_TABLE_100
    , a23 out nocopy JTF_DATE_TABLE
    , a24 out nocopy JTF_NUMBER_TABLE
    , a25 out nocopy JTF_VARCHAR2_TABLE_100
    , a26 out nocopy JTF_DATE_TABLE
    , a27 out nocopy JTF_NUMBER_TABLE
    , a28 out nocopy JTF_VARCHAR2_TABLE_100
    , a29 out nocopy JTF_DATE_TABLE
    , a30 out nocopy JTF_NUMBER_TABLE
    , a31 out nocopy JTF_VARCHAR2_TABLE_100
    , a32 out nocopy JTF_DATE_TABLE
    , a33 out nocopy JTF_NUMBER_TABLE
    , a34 out nocopy JTF_VARCHAR2_TABLE_100
    , a35 out nocopy JTF_DATE_TABLE
    , a36 out nocopy JTF_NUMBER_TABLE
    , a37 out nocopy JTF_VARCHAR2_TABLE_100
    , a38 out nocopy JTF_DATE_TABLE
    , a39 out nocopy JTF_NUMBER_TABLE
    , a40 out nocopy JTF_VARCHAR2_TABLE_100
    , a41 out nocopy JTF_DATE_TABLE
    , a42 out nocopy JTF_NUMBER_TABLE
    , a43 out nocopy JTF_VARCHAR2_TABLE_100
    , a44 out nocopy JTF_DATE_TABLE
    , a45 out nocopy JTF_NUMBER_TABLE
    , a46 out nocopy JTF_VARCHAR2_TABLE_100
    , a47 out nocopy JTF_DATE_TABLE
    , a48 out nocopy JTF_NUMBER_TABLE
    , a49 out nocopy JTF_VARCHAR2_TABLE_100
    , a50 out nocopy JTF_DATE_TABLE
    , a51 out nocopy JTF_NUMBER_TABLE
    , a52 out nocopy JTF_VARCHAR2_TABLE_100
    , a53 out nocopy JTF_DATE_TABLE
    , a54 out nocopy JTF_NUMBER_TABLE
    , a55 out nocopy JTF_VARCHAR2_TABLE_100
    , a56 out nocopy JTF_DATE_TABLE
    , a57 out nocopy JTF_NUMBER_TABLE
    , a58 out nocopy JTF_VARCHAR2_TABLE_100
    , a59 out nocopy JTF_DATE_TABLE
    , a60 out nocopy JTF_NUMBER_TABLE
    , a61 out nocopy JTF_VARCHAR2_TABLE_100
    , a62 out nocopy JTF_DATE_TABLE
    , a63 out nocopy JTF_NUMBER_TABLE
    , a64 out nocopy JTF_VARCHAR2_TABLE_100
    , a65 out nocopy JTF_DATE_TABLE
    , a66 out nocopy JTF_NUMBER_TABLE
    , a67 out nocopy JTF_VARCHAR2_TABLE_100
    , a68 out nocopy JTF_DATE_TABLE
    , a69 out nocopy JTF_NUMBER_TABLE
    , a70 out nocopy JTF_NUMBER_TABLE
    );

  procedure rosetta_table_copy_in_p7(t out nocopy ahl_amp_workbench_pvt.sch_visits_tbl, a0 JTF_NUMBER_TABLE
    , a1 JTF_DATE_TABLE
    , a2 JTF_DATE_TABLE
    );
  procedure rosetta_table_copy_out_p7(t ahl_amp_workbench_pvt.sch_visits_tbl, a0 out nocopy JTF_NUMBER_TABLE
    , a1 out nocopy JTF_DATE_TABLE
    , a2 out nocopy JTF_DATE_TABLE
    );

  procedure rosetta_table_copy_in_p8(t out nocopy ahl_amp_workbench_pvt.resource_input_tbl_type, a0 JTF_NUMBER_TABLE
    , a1 JTF_NUMBER_TABLE
    );
  procedure rosetta_table_copy_out_p8(t ahl_amp_workbench_pvt.resource_input_tbl_type, a0 out nocopy JTF_NUMBER_TABLE
    , a1 out nocopy JTF_NUMBER_TABLE
    );

  procedure rosetta_table_copy_in_p9(t out nocopy ahl_amp_workbench_pvt.resource_output_tbl_type, a0 JTF_DATE_TABLE
    , a1 JTF_NUMBER_TABLE
    , a2 JTF_NUMBER_TABLE
    , a3 JTF_NUMBER_TABLE
    , a4 JTF_NUMBER_TABLE
    , a5 JTF_NUMBER_TABLE
    , a6 JTF_NUMBER_TABLE
    );
  procedure rosetta_table_copy_out_p9(t ahl_amp_workbench_pvt.resource_output_tbl_type, a0 out nocopy JTF_DATE_TABLE
    , a1 out nocopy JTF_NUMBER_TABLE
    , a2 out nocopy JTF_NUMBER_TABLE
    , a3 out nocopy JTF_NUMBER_TABLE
    , a4 out nocopy JTF_NUMBER_TABLE
    , a5 out nocopy JTF_NUMBER_TABLE
    , a6 out nocopy JTF_NUMBER_TABLE
    );

  procedure get_org_sch_graph(p_api_version  NUMBER
    , p_init_msg_list  VARCHAR2
    , p_validation_level  NUMBER
    , x_return_status out nocopy  VARCHAR2
    , x_msg_count out nocopy  NUMBER
    , x_msg_data out nocopy  VARCHAR2
    , p6_a0  NUMBER
    , p6_a1  NUMBER
    , p6_a2  NUMBER
    , p6_a3  VARCHAR2
    , p6_a4  VARCHAR2
    , p6_a5  DATE
    , p6_a6  DATE
    , p6_a7  NUMBER
    , p6_a8  VARCHAR2
    , p7_a0 out nocopy JTF_NUMBER_TABLE
    , p7_a1 out nocopy JTF_NUMBER_TABLE
    , p7_a2 out nocopy JTF_VARCHAR2_TABLE_300
    , p7_a3 out nocopy JTF_NUMBER_TABLE
    , p7_a4 out nocopy JTF_VARCHAR2_TABLE_100
    , p7_a5 out nocopy JTF_NUMBER_TABLE
    , p7_a6 out nocopy JTF_VARCHAR2_TABLE_300
    , p7_a7 out nocopy JTF_VARCHAR2_TABLE_100
    , p7_a8 out nocopy JTF_DATE_TABLE
    , p7_a9 out nocopy JTF_NUMBER_TABLE
    , p7_a10 out nocopy JTF_VARCHAR2_TABLE_100
    , p7_a11 out nocopy JTF_DATE_TABLE
    , p7_a12 out nocopy JTF_NUMBER_TABLE
    , p7_a13 out nocopy JTF_VARCHAR2_TABLE_100
    , p7_a14 out nocopy JTF_DATE_TABLE
    , p7_a15 out nocopy JTF_NUMBER_TABLE
    , p7_a16 out nocopy JTF_VARCHAR2_TABLE_100
    , p7_a17 out nocopy JTF_DATE_TABLE
    , p7_a18 out nocopy JTF_NUMBER_TABLE
    , p7_a19 out nocopy JTF_VARCHAR2_TABLE_100
    , p7_a20 out nocopy JTF_DATE_TABLE
    , p7_a21 out nocopy JTF_NUMBER_TABLE
    , p7_a22 out nocopy JTF_VARCHAR2_TABLE_100
    , p7_a23 out nocopy JTF_DATE_TABLE
    , p7_a24 out nocopy JTF_NUMBER_TABLE
    , p7_a25 out nocopy JTF_VARCHAR2_TABLE_100
    , p7_a26 out nocopy JTF_DATE_TABLE
    , p7_a27 out nocopy JTF_NUMBER_TABLE
    , p7_a28 out nocopy JTF_VARCHAR2_TABLE_100
    , p7_a29 out nocopy JTF_DATE_TABLE
    , p7_a30 out nocopy JTF_NUMBER_TABLE
    , p7_a31 out nocopy JTF_VARCHAR2_TABLE_100
    , p7_a32 out nocopy JTF_DATE_TABLE
    , p7_a33 out nocopy JTF_NUMBER_TABLE
    , p7_a34 out nocopy JTF_VARCHAR2_TABLE_100
    , p7_a35 out nocopy JTF_DATE_TABLE
    , p7_a36 out nocopy JTF_NUMBER_TABLE
    , p7_a37 out nocopy JTF_VARCHAR2_TABLE_100
    , p7_a38 out nocopy JTF_DATE_TABLE
    , p7_a39 out nocopy JTF_NUMBER_TABLE
    , p7_a40 out nocopy JTF_VARCHAR2_TABLE_100
    , p7_a41 out nocopy JTF_DATE_TABLE
    , p7_a42 out nocopy JTF_NUMBER_TABLE
    , p7_a43 out nocopy JTF_VARCHAR2_TABLE_100
    , p7_a44 out nocopy JTF_DATE_TABLE
    , p7_a45 out nocopy JTF_NUMBER_TABLE
    , p7_a46 out nocopy JTF_VARCHAR2_TABLE_100
    , p7_a47 out nocopy JTF_DATE_TABLE
    , p7_a48 out nocopy JTF_NUMBER_TABLE
    , p7_a49 out nocopy JTF_VARCHAR2_TABLE_100
    , p7_a50 out nocopy JTF_DATE_TABLE
    , p7_a51 out nocopy JTF_NUMBER_TABLE
    , p7_a52 out nocopy JTF_VARCHAR2_TABLE_100
    , p7_a53 out nocopy JTF_DATE_TABLE
    , p7_a54 out nocopy JTF_NUMBER_TABLE
    , p7_a55 out nocopy JTF_VARCHAR2_TABLE_100
    , p7_a56 out nocopy JTF_DATE_TABLE
    , p7_a57 out nocopy JTF_NUMBER_TABLE
    , p7_a58 out nocopy JTF_VARCHAR2_TABLE_100
    , p7_a59 out nocopy JTF_DATE_TABLE
    , p7_a60 out nocopy JTF_NUMBER_TABLE
    , p7_a61 out nocopy JTF_VARCHAR2_TABLE_100
    , p7_a62 out nocopy JTF_DATE_TABLE
    , p7_a63 out nocopy JTF_NUMBER_TABLE
    , p7_a64 out nocopy JTF_VARCHAR2_TABLE_100
    , p7_a65 out nocopy JTF_DATE_TABLE
    , p7_a66 out nocopy JTF_NUMBER_TABLE
    , p7_a67 out nocopy JTF_VARCHAR2_TABLE_100
    , p7_a68 out nocopy JTF_DATE_TABLE
    , p7_a69 out nocopy JTF_NUMBER_TABLE
    , p7_a70 out nocopy JTF_NUMBER_TABLE
  );
  procedure get_visits_for_date_org(p_api_version  NUMBER
    , p_init_msg_list  VARCHAR2
    , p_validation_level  NUMBER
    , x_return_status out nocopy  VARCHAR2
    , x_msg_count out nocopy  NUMBER
    , x_msg_data out nocopy  VARCHAR2
    , p6_a0  NUMBER
    , p6_a1  NUMBER
    , p6_a2  NUMBER
    , p6_a3  VARCHAR2
    , p6_a4  VARCHAR2
    , p6_a5  DATE
    , p6_a6  DATE
    , p6_a7  NUMBER
    , p6_a8  VARCHAR2
    , p7_a0 out nocopy  NUMBER
    , p7_a1 out nocopy  NUMBER
    , p7_a2 out nocopy  VARCHAR2
    , p7_a3 out nocopy  NUMBER
    , p7_a4 out nocopy  VARCHAR2
    , p7_a5 out nocopy  NUMBER
    , p7_a6 out nocopy  VARCHAR2
    , p7_a7 out nocopy  VARCHAR2
    , p7_a8 out nocopy  DATE
    , p7_a9 out nocopy  NUMBER
    , p7_a10 out nocopy  VARCHAR2
    , p7_a11 out nocopy  DATE
    , p7_a12 out nocopy  NUMBER
    , p7_a13 out nocopy  VARCHAR2
    , p7_a14 out nocopy  DATE
    , p7_a15 out nocopy  NUMBER
    , p7_a16 out nocopy  VARCHAR2
    , p7_a17 out nocopy  DATE
    , p7_a18 out nocopy  NUMBER
    , p7_a19 out nocopy  VARCHAR2
    , p7_a20 out nocopy  DATE
    , p7_a21 out nocopy  NUMBER
    , p7_a22 out nocopy  VARCHAR2
    , p7_a23 out nocopy  DATE
    , p7_a24 out nocopy  NUMBER
    , p7_a25 out nocopy  VARCHAR2
    , p7_a26 out nocopy  DATE
    , p7_a27 out nocopy  NUMBER
    , p7_a28 out nocopy  VARCHAR2
    , p7_a29 out nocopy  DATE
    , p7_a30 out nocopy  NUMBER
    , p7_a31 out nocopy  VARCHAR2
    , p7_a32 out nocopy  DATE
    , p7_a33 out nocopy  NUMBER
    , p7_a34 out nocopy  VARCHAR2
    , p7_a35 out nocopy  DATE
    , p7_a36 out nocopy  NUMBER
    , p7_a37 out nocopy  VARCHAR2
    , p7_a38 out nocopy  DATE
    , p7_a39 out nocopy  NUMBER
    , p7_a40 out nocopy  VARCHAR2
    , p7_a41 out nocopy  DATE
    , p7_a42 out nocopy  NUMBER
    , p7_a43 out nocopy  VARCHAR2
    , p7_a44 out nocopy  DATE
    , p7_a45 out nocopy  NUMBER
    , p7_a46 out nocopy  VARCHAR2
    , p7_a47 out nocopy  DATE
    , p7_a48 out nocopy  NUMBER
    , p7_a49 out nocopy  VARCHAR2
    , p7_a50 out nocopy  DATE
    , p7_a51 out nocopy  NUMBER
    , p7_a52 out nocopy  VARCHAR2
    , p7_a53 out nocopy  DATE
    , p7_a54 out nocopy  NUMBER
    , p7_a55 out nocopy  VARCHAR2
    , p7_a56 out nocopy  DATE
    , p7_a57 out nocopy  NUMBER
    , p7_a58 out nocopy  VARCHAR2
    , p7_a59 out nocopy  DATE
    , p7_a60 out nocopy  NUMBER
    , p7_a61 out nocopy  VARCHAR2
    , p7_a62 out nocopy  DATE
    , p7_a63 out nocopy  NUMBER
    , p7_a64 out nocopy  VARCHAR2
    , p7_a65 out nocopy  DATE
    , p7_a66 out nocopy  NUMBER
    , p7_a67 out nocopy  VARCHAR2
    , p7_a68 out nocopy  DATE
    , p7_a69 out nocopy  NUMBER
    , p7_a70 out nocopy  NUMBER
    , p8_a0 out nocopy JTF_NUMBER_TABLE
    , p8_a1 out nocopy JTF_DATE_TABLE
    , p8_a2 out nocopy JTF_DATE_TABLE
  );
  procedure get_flt_sch_graph(p_api_version  NUMBER
    , p_init_msg_list  VARCHAR2
    , p_validation_level  NUMBER
    , x_return_status out nocopy  VARCHAR2
    , x_msg_count out nocopy  NUMBER
    , x_msg_data out nocopy  VARCHAR2
    , p6_a0  NUMBER
    , p6_a1  NUMBER
    , p6_a2  VARCHAR2
    , p6_a3  VARCHAR2
    , p6_a4  NUMBER
    , p6_a5  VARCHAR2
    , p6_a6  DATE
    , p6_a7  DATE
    , p6_a8  NUMBER
    , p7_a0 out nocopy JTF_NUMBER_TABLE
    , p7_a1 out nocopy JTF_NUMBER_TABLE
    , p7_a2 out nocopy JTF_VARCHAR2_TABLE_300
    , p7_a3 out nocopy JTF_NUMBER_TABLE
    , p7_a4 out nocopy JTF_VARCHAR2_TABLE_100
    , p7_a5 out nocopy JTF_NUMBER_TABLE
    , p7_a6 out nocopy JTF_VARCHAR2_TABLE_300
    , p7_a7 out nocopy JTF_VARCHAR2_TABLE_100
    , p7_a8 out nocopy JTF_DATE_TABLE
    , p7_a9 out nocopy JTF_NUMBER_TABLE
    , p7_a10 out nocopy JTF_VARCHAR2_TABLE_100
    , p7_a11 out nocopy JTF_DATE_TABLE
    , p7_a12 out nocopy JTF_NUMBER_TABLE
    , p7_a13 out nocopy JTF_VARCHAR2_TABLE_100
    , p7_a14 out nocopy JTF_DATE_TABLE
    , p7_a15 out nocopy JTF_NUMBER_TABLE
    , p7_a16 out nocopy JTF_VARCHAR2_TABLE_100
    , p7_a17 out nocopy JTF_DATE_TABLE
    , p7_a18 out nocopy JTF_NUMBER_TABLE
    , p7_a19 out nocopy JTF_VARCHAR2_TABLE_100
    , p7_a20 out nocopy JTF_DATE_TABLE
    , p7_a21 out nocopy JTF_NUMBER_TABLE
    , p7_a22 out nocopy JTF_VARCHAR2_TABLE_100
    , p7_a23 out nocopy JTF_DATE_TABLE
    , p7_a24 out nocopy JTF_NUMBER_TABLE
    , p7_a25 out nocopy JTF_VARCHAR2_TABLE_100
    , p7_a26 out nocopy JTF_DATE_TABLE
    , p7_a27 out nocopy JTF_NUMBER_TABLE
    , p7_a28 out nocopy JTF_VARCHAR2_TABLE_100
    , p7_a29 out nocopy JTF_DATE_TABLE
    , p7_a30 out nocopy JTF_NUMBER_TABLE
    , p7_a31 out nocopy JTF_VARCHAR2_TABLE_100
    , p7_a32 out nocopy JTF_DATE_TABLE
    , p7_a33 out nocopy JTF_NUMBER_TABLE
    , p7_a34 out nocopy JTF_VARCHAR2_TABLE_100
    , p7_a35 out nocopy JTF_DATE_TABLE
    , p7_a36 out nocopy JTF_NUMBER_TABLE
    , p7_a37 out nocopy JTF_VARCHAR2_TABLE_100
    , p7_a38 out nocopy JTF_DATE_TABLE
    , p7_a39 out nocopy JTF_NUMBER_TABLE
    , p7_a40 out nocopy JTF_VARCHAR2_TABLE_100
    , p7_a41 out nocopy JTF_DATE_TABLE
    , p7_a42 out nocopy JTF_NUMBER_TABLE
    , p7_a43 out nocopy JTF_VARCHAR2_TABLE_100
    , p7_a44 out nocopy JTF_DATE_TABLE
    , p7_a45 out nocopy JTF_NUMBER_TABLE
    , p7_a46 out nocopy JTF_VARCHAR2_TABLE_100
    , p7_a47 out nocopy JTF_DATE_TABLE
    , p7_a48 out nocopy JTF_NUMBER_TABLE
    , p7_a49 out nocopy JTF_VARCHAR2_TABLE_100
    , p7_a50 out nocopy JTF_DATE_TABLE
    , p7_a51 out nocopy JTF_NUMBER_TABLE
    , p7_a52 out nocopy JTF_VARCHAR2_TABLE_100
    , p7_a53 out nocopy JTF_DATE_TABLE
    , p7_a54 out nocopy JTF_NUMBER_TABLE
    , p7_a55 out nocopy JTF_VARCHAR2_TABLE_100
    , p7_a56 out nocopy JTF_DATE_TABLE
    , p7_a57 out nocopy JTF_NUMBER_TABLE
    , p7_a58 out nocopy JTF_VARCHAR2_TABLE_100
    , p7_a59 out nocopy JTF_DATE_TABLE
    , p7_a60 out nocopy JTF_NUMBER_TABLE
    , p7_a61 out nocopy JTF_VARCHAR2_TABLE_100
    , p7_a62 out nocopy JTF_DATE_TABLE
    , p7_a63 out nocopy JTF_NUMBER_TABLE
    , p7_a64 out nocopy JTF_VARCHAR2_TABLE_100
    , p7_a65 out nocopy JTF_DATE_TABLE
    , p7_a66 out nocopy JTF_NUMBER_TABLE
    , p7_a67 out nocopy JTF_VARCHAR2_TABLE_100
    , p7_a68 out nocopy JTF_DATE_TABLE
    , p7_a69 out nocopy JTF_NUMBER_TABLE
    , p7_a70 out nocopy JTF_NUMBER_TABLE
  );
  procedure get_visits_for_date_flt(p_api_version  NUMBER
    , p_init_msg_list  VARCHAR2
    , p_validation_level  NUMBER
    , x_return_status out nocopy  VARCHAR2
    , x_msg_count out nocopy  NUMBER
    , x_msg_data out nocopy  VARCHAR2
    , p6_a0  NUMBER
    , p6_a1  NUMBER
    , p6_a2  VARCHAR2
    , p6_a3  VARCHAR2
    , p6_a4  NUMBER
    , p6_a5  VARCHAR2
    , p6_a6  DATE
    , p6_a7  DATE
    , p6_a8  NUMBER
    , p7_a0 out nocopy  NUMBER
    , p7_a1 out nocopy  NUMBER
    , p7_a2 out nocopy  VARCHAR2
    , p7_a3 out nocopy  NUMBER
    , p7_a4 out nocopy  VARCHAR2
    , p7_a5 out nocopy  NUMBER
    , p7_a6 out nocopy  VARCHAR2
    , p7_a7 out nocopy  VARCHAR2
    , p7_a8 out nocopy  DATE
    , p7_a9 out nocopy  NUMBER
    , p7_a10 out nocopy  VARCHAR2
    , p7_a11 out nocopy  DATE
    , p7_a12 out nocopy  NUMBER
    , p7_a13 out nocopy  VARCHAR2
    , p7_a14 out nocopy  DATE
    , p7_a15 out nocopy  NUMBER
    , p7_a16 out nocopy  VARCHAR2
    , p7_a17 out nocopy  DATE
    , p7_a18 out nocopy  NUMBER
    , p7_a19 out nocopy  VARCHAR2
    , p7_a20 out nocopy  DATE
    , p7_a21 out nocopy  NUMBER
    , p7_a22 out nocopy  VARCHAR2
    , p7_a23 out nocopy  DATE
    , p7_a24 out nocopy  NUMBER
    , p7_a25 out nocopy  VARCHAR2
    , p7_a26 out nocopy  DATE
    , p7_a27 out nocopy  NUMBER
    , p7_a28 out nocopy  VARCHAR2
    , p7_a29 out nocopy  DATE
    , p7_a30 out nocopy  NUMBER
    , p7_a31 out nocopy  VARCHAR2
    , p7_a32 out nocopy  DATE
    , p7_a33 out nocopy  NUMBER
    , p7_a34 out nocopy  VARCHAR2
    , p7_a35 out nocopy  DATE
    , p7_a36 out nocopy  NUMBER
    , p7_a37 out nocopy  VARCHAR2
    , p7_a38 out nocopy  DATE
    , p7_a39 out nocopy  NUMBER
    , p7_a40 out nocopy  VARCHAR2
    , p7_a41 out nocopy  DATE
    , p7_a42 out nocopy  NUMBER
    , p7_a43 out nocopy  VARCHAR2
    , p7_a44 out nocopy  DATE
    , p7_a45 out nocopy  NUMBER
    , p7_a46 out nocopy  VARCHAR2
    , p7_a47 out nocopy  DATE
    , p7_a48 out nocopy  NUMBER
    , p7_a49 out nocopy  VARCHAR2
    , p7_a50 out nocopy  DATE
    , p7_a51 out nocopy  NUMBER
    , p7_a52 out nocopy  VARCHAR2
    , p7_a53 out nocopy  DATE
    , p7_a54 out nocopy  NUMBER
    , p7_a55 out nocopy  VARCHAR2
    , p7_a56 out nocopy  DATE
    , p7_a57 out nocopy  NUMBER
    , p7_a58 out nocopy  VARCHAR2
    , p7_a59 out nocopy  DATE
    , p7_a60 out nocopy  NUMBER
    , p7_a61 out nocopy  VARCHAR2
    , p7_a62 out nocopy  DATE
    , p7_a63 out nocopy  NUMBER
    , p7_a64 out nocopy  VARCHAR2
    , p7_a65 out nocopy  DATE
    , p7_a66 out nocopy  NUMBER
    , p7_a67 out nocopy  VARCHAR2
    , p7_a68 out nocopy  DATE
    , p7_a69 out nocopy  NUMBER
    , p7_a70 out nocopy  NUMBER
    , p8_a0 out nocopy JTF_NUMBER_TABLE
    , p8_a1 out nocopy JTF_DATE_TABLE
    , p8_a2 out nocopy JTF_DATE_TABLE
  );
  procedure get_mc_graph_data(p_api_version  NUMBER
    , p_init_msg_list  VARCHAR2
    , p_commit  VARCHAR2
    , p_validation_level  NUMBER
    , p_default  VARCHAR2
    , p_module_type  VARCHAR2
    , x_return_status out nocopy  VARCHAR2
    , x_msg_count out nocopy  NUMBER
    , x_msg_data out nocopy  VARCHAR2
    , p_organization_id  NUMBER
    , p_department_id  NUMBER
    , p_start_date  DATE
    , p_no_of_days  NUMBER
    , p_max_range  NUMBER
    , p14_a0 in out nocopy JTF_NUMBER_TABLE
    , p14_a1 in out nocopy JTF_NUMBER_TABLE
    , p15_a0 in out nocopy JTF_DATE_TABLE
    , p15_a1 in out nocopy JTF_NUMBER_TABLE
    , p15_a2 in out nocopy JTF_NUMBER_TABLE
    , p15_a3 in out nocopy JTF_NUMBER_TABLE
    , p15_a4 in out nocopy JTF_NUMBER_TABLE
    , p15_a5 in out nocopy JTF_NUMBER_TABLE
    , p15_a6 in out nocopy JTF_NUMBER_TABLE
    , x_plan_date out nocopy  DATE
  );
end ahl_amp_workbench_pvt_w;

CREATE OR REPLACE EDITIONABLE PACKAGE BODY "APPS"."AHL_AMP_WORKBENCH_PVT_W" as
  /* $Header: AHLWAMPB.pls 120.0.12020000.2 2012/12/11 05:48:04 prakkum noship $ */
  procedure rosetta_table_copy_in_p6(t out nocopy ahl_amp_workbench_pvt.sch_graph_results_tbl, a0 JTF_NUMBER_TABLE
    , a1 JTF_NUMBER_TABLE
    , a2 JTF_VARCHAR2_TABLE_300
    , a3 JTF_NUMBER_TABLE
    , a4 JTF_VARCHAR2_TABLE_100
    , a5 JTF_NUMBER_TABLE
    , a6 JTF_VARCHAR2_TABLE_300
    , a7 JTF_VARCHAR2_TABLE_100
    , a8 JTF_DATE_TABLE
    , a9 JTF_NUMBER_TABLE
    , a10 JTF_VARCHAR2_TABLE_100
    , a11 JTF_DATE_TABLE
    , a12 JTF_NUMBER_TABLE
    , a13 JTF_VARCHAR2_TABLE_100
    , a14 JTF_DATE_TABLE
    , a15 JTF_NUMBER_TABLE
    , a16 JTF_VARCHAR2_TABLE_100
    , a17 JTF_DATE_TABLE
    , a18 JTF_NUMBER_TABLE
    , a19 JTF_VARCHAR2_TABLE_100
    , a20 JTF_DATE_TABLE
    , a21 JTF_NUMBER_TABLE
    , a22 JTF_VARCHAR2_TABLE_100
    , a23 JTF_DATE_TABLE
    , a24 JTF_NUMBER_TABLE
    , a25 JTF_VARCHAR2_TABLE_100
    , a26 JTF_DATE_TABLE
    , a27 JTF_NUMBER_TABLE
    , a28 JTF_VARCHAR2_TABLE_100
    , a29 JTF_DATE_TABLE
    , a30 JTF_NUMBER_TABLE
    , a31 JTF_VARCHAR2_TABLE_100
    , a32 JTF_DATE_TABLE
    , a33 JTF_NUMBER_TABLE
    , a34 JTF_VARCHAR2_TABLE_100
    , a35 JTF_DATE_TABLE
    , a36 JTF_NUMBER_TABLE
    , a37 JTF_VARCHAR2_TABLE_100
    , a38 JTF_DATE_TABLE
    , a39 JTF_NUMBER_TABLE
    , a40 JTF_VARCHAR2_TABLE_100
    , a41 JTF_DATE_TABLE
    , a42 JTF_NUMBER_TABLE
    , a43 JTF_VARCHAR2_TABLE_100
    , a44 JTF_DATE_TABLE
    , a45 JTF_NUMBER_TABLE
    , a46 JTF_VARCHAR2_TABLE_100
    , a47 JTF_DATE_TABLE
    , a48 JTF_NUMBER_TABLE
    , a49 JTF_VARCHAR2_TABLE_100
    , a50 JTF_DATE_TABLE
    , a51 JTF_NUMBER_TABLE
    , a52 JTF_VARCHAR2_TABLE_100
    , a53 JTF_DATE_TABLE
    , a54 JTF_NUMBER_TABLE
    , a55 JTF_VARCHAR2_TABLE_100
    , a56 JTF_DATE_TABLE
    , a57 JTF_NUMBER_TABLE
    , a58 JTF_VARCHAR2_TABLE_100
    , a59 JTF_DATE_TABLE
    , a60 JTF_NUMBER_TABLE
    , a61 JTF_VARCHAR2_TABLE_100
    , a62 JTF_DATE_TABLE
    , a63 JTF_NUMBER_TABLE
    , a64 JTF_VARCHAR2_TABLE_100
    , a65 JTF_DATE_TABLE
    , a66 JTF_NUMBER_TABLE
    , a67 JTF_VARCHAR2_TABLE_100
    , a68 JTF_DATE_TABLE
    , a69 JTF_NUMBER_TABLE
    , a70 JTF_NUMBER_TABLE
    ) as
    ddindx binary_integer; indx binary_integer;
  begin
  if a0 is not null and a0.count > 0 then
      if a0.count > 0 then
        indx := a0.first;
        ddindx := 1;
        while true loop
          t(ddindx).org_id := a0(indx);
          t(ddindx).department_id := a1(indx);
          t(ddindx).department_desc := a2(indx);
          t(ddindx).space_id := a3(indx);
          t(ddindx).space_name := a4(indx);
          t(ddindx).unit_id := a5(indx);
          t(ddindx).unit_name := a6(indx);
          t(ddindx).schedule_type_1 := a7(indx);
          t(ddindx).visit_date_1 := a8(indx);
          t(ddindx).visit_id_1 := a9(indx);
          t(ddindx).schedule_type_2 := a10(indx);
          t(ddindx).visit_date_2 := a11(indx);
          t(ddindx).visit_id_2 := a12(indx);
          t(ddindx).schedule_type_3 := a13(indx);
          t(ddindx).visit_date_3 := a14(indx);
          t(ddindx).visit_id_3 := a15(indx);
          t(ddindx).schedule_type_4 := a16(indx);
          t(ddindx).visit_date_4 := a17(indx);
          t(ddindx).visit_id_4 := a18(indx);
          t(ddindx).schedule_type_5 := a19(indx);
          t(ddindx).visit_date_5 := a20(indx);
          t(ddindx).visit_id_5 := a21(indx);
          t(ddindx).schedule_type_6 := a22(indx);
          t(ddindx).visit_date_6 := a23(indx);
          t(ddindx).visit_id_6 := a24(indx);
          t(ddindx).schedule_type_7 := a25(indx);
          t(ddindx).visit_date_7 := a26(indx);
          t(ddindx).visit_id_7 := a27(indx);
          t(ddindx).schedule_type_8 := a28(indx);
          t(ddindx).visit_date_8 := a29(indx);
          t(ddindx).visit_id_8 := a30(indx);
          t(ddindx).schedule_type_9 := a31(indx);
          t(ddindx).visit_date_9 := a32(indx);
          t(ddindx).visit_id_9 := a33(indx);
          t(ddindx).schedule_type_10 := a34(indx);
          t(ddindx).visit_date_10 := a35(indx);
          t(ddindx).visit_id_10 := a36(indx);
          t(ddindx).schedule_type_11 := a37(indx);
          t(ddindx).visit_date_11 := a38(indx);
          t(ddindx).visit_id_11 := a39(indx);
          t(ddindx).schedule_type_12 := a40(indx);
          t(ddindx).visit_date_12 := a41(indx);
          t(ddindx).visit_id_12 := a42(indx);
          t(ddindx).schedule_type_13 := a43(indx);
          t(ddindx).visit_date_13 := a44(indx);
          t(ddindx).visit_id_13 := a45(indx);
          t(ddindx).schedule_type_14 := a46(indx);
          t(ddindx).visit_date_14 := a47(indx);
          t(ddindx).visit_id_14 := a48(indx);
          t(ddindx).schedule_type_15 := a49(indx);
          t(ddindx).visit_date_15 := a50(indx);
          t(ddindx).visit_id_15 := a51(indx);
          t(ddindx).schedule_type_16 := a52(indx);
          t(ddindx).visit_date_16 := a53(indx);
          t(ddindx).visit_id_16 := a54(indx);
          t(ddindx).schedule_type_17 := a55(indx);
          t(ddindx).visit_date_17 := a56(indx);
          t(ddindx).visit_id_17 := a57(indx);
          t(ddindx).schedule_type_18 := a58(indx);
          t(ddindx).visit_date_18 := a59(indx);
          t(ddindx).visit_id_18 := a60(indx);
          t(ddindx).schedule_type_19 := a61(indx);
          t(ddindx).visit_date_19 := a62(indx);
          t(ddindx).visit_id_19 := a63(indx);
          t(ddindx).schedule_type_20 := a64(indx);
          t(ddindx).visit_date_20 := a65(indx);
          t(ddindx).visit_id_20 := a66(indx);
          t(ddindx).schedule_type_21 := a67(indx);
          t(ddindx).visit_date_21 := a68(indx);
          t(ddindx).visit_id_21 := a69(indx);
          if a70(indx) is null
            then t(ddindx).filter_rec := null;
          elsif a70(indx) = 0
            then t(ddindx).filter_rec := false;
          else t(ddindx).filter_rec := true;
          end if;
          ddindx := ddindx+1;
          if a0.last =indx
            then exit;
          end if;
          indx := a0.next(indx);
        end loop;
      end if;
   end if;
  end rosetta_table_copy_in_p6;
  procedure rosetta_table_copy_out_p6(t ahl_amp_workbench_pvt.sch_graph_results_tbl, a0 out nocopy JTF_NUMBER_TABLE
    , a1 out nocopy JTF_NUMBER_TABLE
    , a2 out nocopy JTF_VARCHAR2_TABLE_300
    , a3 out nocopy JTF_NUMBER_TABLE
    , a4 out nocopy JTF_VARCHAR2_TABLE_100
    , a5 out nocopy JTF_NUMBER_TABLE
    , a6 out nocopy JTF_VARCHAR2_TABLE_300
    , a7 out nocopy JTF_VARCHAR2_TABLE_100
    , a8 out nocopy JTF_DATE_TABLE
    , a9 out nocopy JTF_NUMBER_TABLE
    , a10 out nocopy JTF_VARCHAR2_TABLE_100
    , a11 out nocopy JTF_DATE_TABLE
    , a12 out nocopy JTF_NUMBER_TABLE
    , a13 out nocopy JTF_VARCHAR2_TABLE_100
    , a14 out nocopy JTF_DATE_TABLE
    , a15 out nocopy JTF_NUMBER_TABLE
    , a16 out nocopy JTF_VARCHAR2_TABLE_100
    , a17 out nocopy JTF_DATE_TABLE
    , a18 out nocopy JTF_NUMBER_TABLE
    , a19 out nocopy JTF_VARCHAR2_TABLE_100
    , a20 out nocopy JTF_DATE_TABLE
    , a21 out nocopy JTF_NUMBER_TABLE
    , a22 out nocopy JTF_VARCHAR2_TABLE_100
    , a23 out nocopy JTF_DATE_TABLE
    , a24 out nocopy JTF_NUMBER_TABLE
    , a25 out nocopy JTF_VARCHAR2_TABLE_100
    , a26 out nocopy JTF_DATE_TABLE
    , a27 out nocopy JTF_NUMBER_TABLE
    , a28 out nocopy JTF_VARCHAR2_TABLE_100
    , a29 out nocopy JTF_DATE_TABLE
    , a30 out nocopy JTF_NUMBER_TABLE
    , a31 out nocopy JTF_VARCHAR2_TABLE_100
    , a32 out nocopy JTF_DATE_TABLE
    , a33 out nocopy JTF_NUMBER_TABLE
    , a34 out nocopy JTF_VARCHAR2_TABLE_100
    , a35 out nocopy JTF_DATE_TABLE
    , a36 out nocopy JTF_NUMBER_TABLE
    , a37 out nocopy JTF_VARCHAR2_TABLE_100
    , a38 out nocopy JTF_DATE_TABLE
    , a39 out nocopy JTF_NUMBER_TABLE
    , a40 out nocopy JTF_VARCHAR2_TABLE_100
    , a41 out nocopy JTF_DATE_TABLE
    , a42 out nocopy JTF_NUMBER_TABLE
    , a43 out nocopy JTF_VARCHAR2_TABLE_100
    , a44 out nocopy JTF_DATE_TABLE
    , a45 out nocopy JTF_NUMBER_TABLE
    , a46 out nocopy JTF_VARCHAR2_TABLE_100
    , a47 out nocopy JTF_DATE_TABLE
    , a48 out nocopy JTF_NUMBER_TABLE
    , a49 out nocopy JTF_VARCHAR2_TABLE_100
    , a50 out nocopy JTF_DATE_TABLE
    , a51 out nocopy JTF_NUMBER_TABLE
    , a52 out nocopy JTF_VARCHAR2_TABLE_100
    , a53 out nocopy JTF_DATE_TABLE
    , a54 out nocopy JTF_NUMBER_TABLE
    , a55 out nocopy JTF_VARCHAR2_TABLE_100
    , a56 out nocopy JTF_DATE_TABLE
    , a57 out nocopy JTF_NUMBER_TABLE
    , a58 out nocopy JTF_VARCHAR2_TABLE_100
    , a59 out nocopy JTF_DATE_TABLE
    , a60 out nocopy JTF_NUMBER_TABLE
    , a61 out nocopy JTF_VARCHAR2_TABLE_100
    , a62 out nocopy JTF_DATE_TABLE
    , a63 out nocopy JTF_NUMBER_TABLE
    , a64 out nocopy JTF_VARCHAR2_TABLE_100
    , a65 out nocopy JTF_DATE_TABLE
    , a66 out nocopy JTF_NUMBER_TABLE
    , a67 out nocopy JTF_VARCHAR2_TABLE_100
    , a68 out nocopy JTF_DATE_TABLE
    , a69 out nocopy JTF_NUMBER_TABLE
    , a70 out nocopy JTF_NUMBER_TABLE
    ) as
    ddindx binary_integer; indx binary_integer;
  begin
  if t is null or t.count = 0 then
    a0 := JTF_NUMBER_TABLE();
    a1 := JTF_NUMBER_TABLE();
    a2 := JTF_VARCHAR2_TABLE_300();
    a3 := JTF_NUMBER_TABLE();
    a4 := JTF_VARCHAR2_TABLE_100();
    a5 := JTF_NUMBER_TABLE();
    a6 := JTF_VARCHAR2_TABLE_300();
    a7 := JTF_VARCHAR2_TABLE_100();
    a8 := JTF_DATE_TABLE();
    a9 := JTF_NUMBER_TABLE();
    a10 := JTF_VARCHAR2_TABLE_100();
    a11 := JTF_DATE_TABLE();
    a12 := JTF_NUMBER_TABLE();
    a13 := JTF_VARCHAR2_TABLE_100();
    a14 := JTF_DATE_TABLE();
    a15 := JTF_NUMBER_TABLE();
    a16 := JTF_VARCHAR2_TABLE_100();
    a17 := JTF_DATE_TABLE();
    a18 := JTF_NUMBER_TABLE();
    a19 := JTF_VARCHAR2_TABLE_100();
    a20 := JTF_DATE_TABLE();
    a21 := JTF_NUMBER_TABLE();
    a22 := JTF_VARCHAR2_TABLE_100();
    a23 := JTF_DATE_TABLE();
    a24 := JTF_NUMBER_TABLE();
    a25 := JTF_VARCHAR2_TABLE_100();
    a26 := JTF_DATE_TABLE();
    a27 := JTF_NUMBER_TABLE();
    a28 := JTF_VARCHAR2_TABLE_100();
    a29 := JTF_DATE_TABLE();
    a30 := JTF_NUMBER_TABLE();
    a31 := JTF_VARCHAR2_TABLE_100();
    a32 := JTF_DATE_TABLE();
    a33 := JTF_NUMBER_TABLE();
    a34 := JTF_VARCHAR2_TABLE_100();
    a35 := JTF_DATE_TABLE();
    a36 := JTF_NUMBER_TABLE();
    a37 := JTF_VARCHAR2_TABLE_100();
    a38 := JTF_DATE_TABLE();
    a39 := JTF_NUMBER_TABLE();
    a40 := JTF_VARCHAR2_TABLE_100();
    a41 := JTF_DATE_TABLE();
    a42 := JTF_NUMBER_TABLE();
    a43 := JTF_VARCHAR2_TABLE_100();
    a44 := JTF_DATE_TABLE();
    a45 := JTF_NUMBER_TABLE();
    a46 := JTF_VARCHAR2_TABLE_100();
    a47 := JTF_DATE_TABLE();
    a48 := JTF_NUMBER_TABLE();
    a49 := JTF_VARCHAR2_TABLE_100();
    a50 := JTF_DATE_TABLE();
    a51 := JTF_NUMBER_TABLE();
    a52 := JTF_VARCHAR2_TABLE_100();
    a53 := JTF_DATE_TABLE();
    a54 := JTF_NUMBER_TABLE();
    a55 := JTF_VARCHAR2_TABLE_100();
    a56 := JTF_DATE_TABLE();
    a57 := JTF_NUMBER_TABLE();
    a58 := JTF_VARCHAR2_TABLE_100();
    a59 := JTF_DATE_TABLE();
    a60 := JTF_NUMBER_TABLE();
    a61 := JTF_VARCHAR2_TABLE_100();
    a62 := JTF_DATE_TABLE();
    a63 := JTF_NUMBER_TABLE();
    a64 := JTF_VARCHAR2_TABLE_100();
    a65 := JTF_DATE_TABLE();
    a66 := JTF_NUMBER_TABLE();
    a67 := JTF_VARCHAR2_TABLE_100();
    a68 := JTF_DATE_TABLE();
    a69 := JTF_NUMBER_TABLE();
    a70 := JTF_NUMBER_TABLE();
  else
      a0 := JTF_NUMBER_TABLE();
      a1 := JTF_NUMBER_TABLE();
      a2 := JTF_VARCHAR2_TABLE_300();
      a3 := JTF_NUMBER_TABLE();
      a4 := JTF_VARCHAR2_TABLE_100();
      a5 := JTF_NUMBER_TABLE();
      a6 := JTF_VARCHAR2_TABLE_300();
      a7 := JTF_VARCHAR2_TABLE_100();
      a8 := JTF_DATE_TABLE();
      a9 := JTF_NUMBER_TABLE();
      a10 := JTF_VARCHAR2_TABLE_100();
      a11 := JTF_DATE_TABLE();
      a12 := JTF_NUMBER_TABLE();
      a13 := JTF_VARCHAR2_TABLE_100();
      a14 := JTF_DATE_TABLE();
      a15 := JTF_NUMBER_TABLE();
      a16 := JTF_VARCHAR2_TABLE_100();
      a17 := JTF_DATE_TABLE();
      a18 := JTF_NUMBER_TABLE();
      a19 := JTF_VARCHAR2_TABLE_100();
      a20 := JTF_DATE_TABLE();
      a21 := JTF_NUMBER_TABLE();
      a22 := JTF_VARCHAR2_TABLE_100();
      a23 := JTF_DATE_TABLE();
      a24 := JTF_NUMBER_TABLE();
      a25 := JTF_VARCHAR2_TABLE_100();
      a26 := JTF_DATE_TABLE();
      a27 := JTF_NUMBER_TABLE();
      a28 := JTF_VARCHAR2_TABLE_100();
      a29 := JTF_DATE_TABLE();
      a30 := JTF_NUMBER_TABLE();
      a31 := JTF_VARCHAR2_TABLE_100();
      a32 := JTF_DATE_TABLE();
      a33 := JTF_NUMBER_TABLE();
      a34 := JTF_VARCHAR2_TABLE_100();
      a35 := JTF_DATE_TABLE();
      a36 := JTF_NUMBER_TABLE();
      a37 := JTF_VARCHAR2_TABLE_100();
      a38 := JTF_DATE_TABLE();
      a39 := JTF_NUMBER_TABLE();
      a40 := JTF_VARCHAR2_TABLE_100();
      a41 := JTF_DATE_TABLE();
      a42 := JTF_NUMBER_TABLE();
      a43 := JTF_VARCHAR2_TABLE_100();
      a44 := JTF_DATE_TABLE();
      a45 := JTF_NUMBER_TABLE();
      a46 := JTF_VARCHAR2_TABLE_100();
      a47 := JTF_DATE_TABLE();
      a48 := JTF_NUMBER_TABLE();
      a49 := JTF_VARCHAR2_TABLE_100();
      a50 := JTF_DATE_TABLE();
      a51 := JTF_NUMBER_TABLE();
      a52 := JTF_VARCHAR2_TABLE_100();
      a53 := JTF_DATE_TABLE();
      a54 := JTF_NUMBER_TABLE();
      a55 := JTF_VARCHAR2_TABLE_100();
      a56 := JTF_DATE_TABLE();
      a57 := JTF_NUMBER_TABLE();
      a58 := JTF_VARCHAR2_TABLE_100();
      a59 := JTF_DATE_TABLE();
      a60 := JTF_NUMBER_TABLE();
      a61 := JTF_VARCHAR2_TABLE_100();
      a62 := JTF_DATE_TABLE();
      a63 := JTF_NUMBER_TABLE();
      a64 := JTF_VARCHAR2_TABLE_100();
      a65 := JTF_DATE_TABLE();
      a66 := JTF_NUMBER_TABLE();
      a67 := JTF_VARCHAR2_TABLE_100();
      a68 := JTF_DATE_TABLE();
      a69 := JTF_NUMBER_TABLE();
      a70 := JTF_NUMBER_TABLE();
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
        a29.extend(t.count);
        a30.extend(t.count);
        a31.extend(t.count);
        a32.extend(t.count);
        a33.extend(t.count);
        a34.extend(t.count);
        a35.extend(t.count);
        a36.extend(t.count);
        a37.extend(t.count);
        a38.extend(t.count);
        a39.extend(t.count);
        a40.extend(t.count);
        a41.extend(t.count);
        a42.extend(t.count);
        a43.extend(t.count);
        a44.extend(t.count);
        a45.extend(t.count);
        a46.extend(t.count);
        a47.extend(t.count);
        a48.extend(t.count);
        a49.extend(t.count);
        a50.extend(t.count);
        a51.extend(t.count);
        a52.extend(t.count);
        a53.extend(t.count);
        a54.extend(t.count);
        a55.extend(t.count);
        a56.extend(t.count);
        a57.extend(t.count);
        a58.extend(t.count);
        a59.extend(t.count);
        a60.extend(t.count);
        a61.extend(t.count);
        a62.extend(t.count);
        a63.extend(t.count);
        a64.extend(t.count);
        a65.extend(t.count);
        a66.extend(t.count);
        a67.extend(t.count);
        a68.extend(t.count);
        a69.extend(t.count);
        a70.extend(t.count);
        ddindx := t.first;
        indx := 1;
        while true loop
          a0(indx) := t(ddindx).org_id;
          a1(indx) := t(ddindx).department_id;
          a2(indx) := t(ddindx).department_desc;
          a3(indx) := t(ddindx).space_id;
          a4(indx) := t(ddindx).space_name;
          a5(indx) := t(ddindx).unit_id;
          a6(indx) := t(ddindx).unit_name;
          a7(indx) := t(ddindx).schedule_type_1;
          a8(indx) := t(ddindx).visit_date_1;
          a9(indx) := t(ddindx).visit_id_1;
          a10(indx) := t(ddindx).schedule_type_2;
          a11(indx) := t(ddindx).visit_date_2;
          a12(indx) := t(ddindx).visit_id_2;
          a13(indx) := t(ddindx).schedule_type_3;
          a14(indx) := t(ddindx).visit_date_3;
          a15(indx) := t(ddindx).visit_id_3;
          a16(indx) := t(ddindx).schedule_type_4;
          a17(indx) := t(ddindx).visit_date_4;
          a18(indx) := t(ddindx).visit_id_4;
          a19(indx) := t(ddindx).schedule_type_5;
          a20(indx) := t(ddindx).visit_date_5;
          a21(indx) := t(ddindx).visit_id_5;
          a22(indx) := t(ddindx).schedule_type_6;
          a23(indx) := t(ddindx).visit_date_6;
          a24(indx) := t(ddindx).visit_id_6;
          a25(indx) := t(ddindx).schedule_type_7;
          a26(indx) := t(ddindx).visit_date_7;
          a27(indx) := t(ddindx).visit_id_7;
          a28(indx) := t(ddindx).schedule_type_8;
          a29(indx) := t(ddindx).visit_date_8;
          a30(indx) := t(ddindx).visit_id_8;
          a31(indx) := t(ddindx).schedule_type_9;
          a32(indx) := t(ddindx).visit_date_9;
          a33(indx) := t(ddindx).visit_id_9;
          a34(indx) := t(ddindx).schedule_type_10;
          a35(indx) := t(ddindx).visit_date_10;
          a36(indx) := t(ddindx).visit_id_10;
          a37(indx) := t(ddindx).schedule_type_11;
          a38(indx) := t(ddindx).visit_date_11;
          a39(indx) := t(ddindx).visit_id_11;
          a40(indx) := t(ddindx).schedule_type_12;
          a41(indx) := t(ddindx).visit_date_12;
          a42(indx) := t(ddindx).visit_id_12;
          a43(indx) := t(ddindx).schedule_type_13;
          a44(indx) := t(ddindx).visit_date_13;
          a45(indx) := t(ddindx).visit_id_13;
          a46(indx) := t(ddindx).schedule_type_14;
          a47(indx) := t(ddindx).visit_date_14;
          a48(indx) := t(ddindx).visit_id_14;
          a49(indx) := t(ddindx).schedule_type_15;
          a50(indx) := t(ddindx).visit_date_15;
          a51(indx) := t(ddindx).visit_id_15;
          a52(indx) := t(ddindx).schedule_type_16;
          a53(indx) := t(ddindx).visit_date_16;
          a54(indx) := t(ddindx).visit_id_16;
          a55(indx) := t(ddindx).schedule_type_17;
          a56(indx) := t(ddindx).visit_date_17;
          a57(indx) := t(ddindx).visit_id_17;
          a58(indx) := t(ddindx).schedule_type_18;
          a59(indx) := t(ddindx).visit_date_18;
          a60(indx) := t(ddindx).visit_id_18;
          a61(indx) := t(ddindx).schedule_type_19;
          a62(indx) := t(ddindx).visit_date_19;
          a63(indx) := t(ddindx).visit_id_19;
          a64(indx) := t(ddindx).schedule_type_20;
          a65(indx) := t(ddindx).visit_date_20;
          a66(indx) := t(ddindx).visit_id_20;
          a67(indx) := t(ddindx).schedule_type_21;
          a68(indx) := t(ddindx).visit_date_21;
          a69(indx) := t(ddindx).visit_id_21;
          if t(ddindx).filter_rec is null
            then a70(indx) := null;
          elsif t(ddindx).filter_rec
            then a70(indx) := 1;
          else a70(indx) := 0;
          end if;
          indx := indx+1;
          if t.last =ddindx
            then exit;
          end if;
          ddindx := t.next(ddindx);
        end loop;
      end if;
   end if;
  end rosetta_table_copy_out_p6;

  procedure rosetta_table_copy_in_p7(t out nocopy ahl_amp_workbench_pvt.sch_visits_tbl, a0 JTF_NUMBER_TABLE
    , a1 JTF_DATE_TABLE
    , a2 JTF_DATE_TABLE
    ) as
    ddindx binary_integer; indx binary_integer;
  begin
  if a0 is not null and a0.count > 0 then
      if a0.count > 0 then
        indx := a0.first;
        ddindx := 1;
        while true loop
          t(ddindx).visit_id := a0(indx);
          t(ddindx).start_date := a1(indx);
          t(ddindx).end_date := a2(indx);
          ddindx := ddindx+1;
          if a0.last =indx
            then exit;
          end if;
          indx := a0.next(indx);
        end loop;
      end if;
   end if;
  end rosetta_table_copy_in_p7;
  procedure rosetta_table_copy_out_p7(t ahl_amp_workbench_pvt.sch_visits_tbl, a0 out nocopy JTF_NUMBER_TABLE
    , a1 out nocopy JTF_DATE_TABLE
    , a2 out nocopy JTF_DATE_TABLE
    ) as
    ddindx binary_integer; indx binary_integer;
  begin
  if t is null or t.count = 0 then
    a0 := JTF_NUMBER_TABLE();
    a1 := JTF_DATE_TABLE();
    a2 := JTF_DATE_TABLE();
  else
      a0 := JTF_NUMBER_TABLE();
      a1 := JTF_DATE_TABLE();
      a2 := JTF_DATE_TABLE();
      if t.count > 0 then
        a0.extend(t.count);
        a1.extend(t.count);
        a2.extend(t.count);
        ddindx := t.first;
        indx := 1;
        while true loop
          a0(indx) := t(ddindx).visit_id;
          a1(indx) := t(ddindx).start_date;
          a2(indx) := t(ddindx).end_date;
          indx := indx+1;
          if t.last =ddindx
            then exit;
          end if;
          ddindx := t.next(ddindx);
        end loop;
      end if;
   end if;
  end rosetta_table_copy_out_p7;

  procedure rosetta_table_copy_in_p8(t out nocopy ahl_amp_workbench_pvt.resource_input_tbl_type, a0 JTF_NUMBER_TABLE
    , a1 JTF_NUMBER_TABLE
    ) as
    ddindx binary_integer; indx binary_integer;
  begin
  if a0 is not null and a0.count > 0 then
      if a0.count > 0 then
        indx := a0.first;
        ddindx := 1;
        while true loop
          t(ddindx).resource_id := a0(indx);
          t(ddindx).resource_availability := a1(indx);
          ddindx := ddindx+1;
          if a0.last =indx
            then exit;
          end if;
          indx := a0.next(indx);
        end loop;
      end if;
   end if;
  end rosetta_table_copy_in_p8;
  procedure rosetta_table_copy_out_p8(t ahl_amp_workbench_pvt.resource_input_tbl_type, a0 out nocopy JTF_NUMBER_TABLE
    , a1 out nocopy JTF_NUMBER_TABLE
    ) as
    ddindx binary_integer; indx binary_integer;
  begin
  if t is null or t.count = 0 then
    a0 := JTF_NUMBER_TABLE();
    a1 := JTF_NUMBER_TABLE();
  else
      a0 := JTF_NUMBER_TABLE();
      a1 := JTF_NUMBER_TABLE();
      if t.count > 0 then
        a0.extend(t.count);
        a1.extend(t.count);
        ddindx := t.first;
        indx := 1;
        while true loop
          a0(indx) := t(ddindx).resource_id;
          a1(indx) := t(ddindx).resource_availability;
          indx := indx+1;
          if t.last =ddindx
            then exit;
          end if;
          ddindx := t.next(ddindx);
        end loop;
      end if;
   end if;
  end rosetta_table_copy_out_p8;

  procedure rosetta_table_copy_in_p9(t out nocopy ahl_amp_workbench_pvt.resource_output_tbl_type, a0 JTF_DATE_TABLE
    , a1 JTF_NUMBER_TABLE
    , a2 JTF_NUMBER_TABLE
    , a3 JTF_NUMBER_TABLE
    , a4 JTF_NUMBER_TABLE
    , a5 JTF_NUMBER_TABLE
    , a6 JTF_NUMBER_TABLE
    ) as
    ddindx binary_integer; indx binary_integer;
  begin
  if a0 is not null and a0.count > 0 then
      if a0.count > 0 then
        indx := a0.first;
        ddindx := 1;
        while true loop
          t(ddindx).on_date := a0(indx);
          t(ddindx).cent_percent_capacity := a1(indx);
          t(ddindx).r1_capacity := a2(indx);
          t(ddindx).r2_capacity := a3(indx);
          t(ddindx).r3_capacity := a4(indx);
          t(ddindx).r4_capacity := a5(indx);
          t(ddindx).r5_capacity := a6(indx);
          ddindx := ddindx+1;
          if a0.last =indx
            then exit;
          end if;
          indx := a0.next(indx);
        end loop;
      end if;
   end if;
  end rosetta_table_copy_in_p9;
  procedure rosetta_table_copy_out_p9(t ahl_amp_workbench_pvt.resource_output_tbl_type, a0 out nocopy JTF_DATE_TABLE
    , a1 out nocopy JTF_NUMBER_TABLE
    , a2 out nocopy JTF_NUMBER_TABLE
    , a3 out nocopy JTF_NUMBER_TABLE
    , a4 out nocopy JTF_NUMBER_TABLE
    , a5 out nocopy JTF_NUMBER_TABLE
    , a6 out nocopy JTF_NUMBER_TABLE
    ) as
    ddindx binary_integer; indx binary_integer;
  begin
  if t is null or t.count = 0 then
    a0 := JTF_DATE_TABLE();
    a1 := JTF_NUMBER_TABLE();
    a2 := JTF_NUMBER_TABLE();
    a3 := JTF_NUMBER_TABLE();
    a4 := JTF_NUMBER_TABLE();
    a5 := JTF_NUMBER_TABLE();
    a6 := JTF_NUMBER_TABLE();
  else
      a0 := JTF_DATE_TABLE();
      a1 := JTF_NUMBER_TABLE();
      a2 := JTF_NUMBER_TABLE();
      a3 := JTF_NUMBER_TABLE();
      a4 := JTF_NUMBER_TABLE();
      a5 := JTF_NUMBER_TABLE();
      a6 := JTF_NUMBER_TABLE();
      if t.count > 0 then
        a0.extend(t.count);
        a1.extend(t.count);
        a2.extend(t.count);
        a3.extend(t.count);
        a4.extend(t.count);
        a5.extend(t.count);
        a6.extend(t.count);
        ddindx := t.first;
        indx := 1;
        while true loop
          a0(indx) := t(ddindx).on_date;
          a1(indx) := t(ddindx).cent_percent_capacity;
          a2(indx) := t(ddindx).r1_capacity;
          a3(indx) := t(ddindx).r2_capacity;
          a4(indx) := t(ddindx).r3_capacity;
          a5(indx) := t(ddindx).r4_capacity;
          a6(indx) := t(ddindx).r5_capacity;
          indx := indx+1;
          if t.last =ddindx
            then exit;
          end if;
          ddindx := t.next(ddindx);
        end loop;
      end if;
   end if;
  end rosetta_table_copy_out_p9;

  procedure get_org_sch_graph(p_api_version  NUMBER
    , p_init_msg_list  VARCHAR2
    , p_validation_level  NUMBER
    , x_return_status out nocopy  VARCHAR2
    , x_msg_count out nocopy  NUMBER
    , x_msg_data out nocopy  VARCHAR2
    , p6_a0  NUMBER
    , p6_a1  NUMBER
    , p6_a2  NUMBER
    , p6_a3  VARCHAR2
    , p6_a4  VARCHAR2
    , p6_a5  DATE
    , p6_a6  DATE
    , p6_a7  NUMBER
    , p6_a8  VARCHAR2
    , p7_a0 out nocopy JTF_NUMBER_TABLE
    , p7_a1 out nocopy JTF_NUMBER_TABLE
    , p7_a2 out nocopy JTF_VARCHAR2_TABLE_300
    , p7_a3 out nocopy JTF_NUMBER_TABLE
    , p7_a4 out nocopy JTF_VARCHAR2_TABLE_100
    , p7_a5 out nocopy JTF_NUMBER_TABLE
    , p7_a6 out nocopy JTF_VARCHAR2_TABLE_300
    , p7_a7 out nocopy JTF_VARCHAR2_TABLE_100
    , p7_a8 out nocopy JTF_DATE_TABLE
    , p7_a9 out nocopy JTF_NUMBER_TABLE
    , p7_a10 out nocopy JTF_VARCHAR2_TABLE_100
    , p7_a11 out nocopy JTF_DATE_TABLE
    , p7_a12 out nocopy JTF_NUMBER_TABLE
    , p7_a13 out nocopy JTF_VARCHAR2_TABLE_100
    , p7_a14 out nocopy JTF_DATE_TABLE
    , p7_a15 out nocopy JTF_NUMBER_TABLE
    , p7_a16 out nocopy JTF_VARCHAR2_TABLE_100
    , p7_a17 out nocopy JTF_DATE_TABLE
    , p7_a18 out nocopy JTF_NUMBER_TABLE
    , p7_a19 out nocopy JTF_VARCHAR2_TABLE_100
    , p7_a20 out nocopy JTF_DATE_TABLE
    , p7_a21 out nocopy JTF_NUMBER_TABLE
    , p7_a22 out nocopy JTF_VARCHAR2_TABLE_100
    , p7_a23 out nocopy JTF_DATE_TABLE
    , p7_a24 out nocopy JTF_NUMBER_TABLE
    , p7_a25 out nocopy JTF_VARCHAR2_TABLE_100
    , p7_a26 out nocopy JTF_DATE_TABLE
    , p7_a27 out nocopy JTF_NUMBER_TABLE
    , p7_a28 out nocopy JTF_VARCHAR2_TABLE_100
    , p7_a29 out nocopy JTF_DATE_TABLE
    , p7_a30 out nocopy JTF_NUMBER_TABLE
    , p7_a31 out nocopy JTF_VARCHAR2_TABLE_100
    , p7_a32 out nocopy JTF_DATE_TABLE
    , p7_a33 out nocopy JTF_NUMBER_TABLE
    , p7_a34 out nocopy JTF_VARCHAR2_TABLE_100
    , p7_a35 out nocopy JTF_DATE_TABLE
    , p7_a36 out nocopy JTF_NUMBER_TABLE
    , p7_a37 out nocopy JTF_VARCHAR2_TABLE_100
    , p7_a38 out nocopy JTF_DATE_TABLE
    , p7_a39 out nocopy JTF_NUMBER_TABLE
    , p7_a40 out nocopy JTF_VARCHAR2_TABLE_100
    , p7_a41 out nocopy JTF_DATE_TABLE
    , p7_a42 out nocopy JTF_NUMBER_TABLE
    , p7_a43 out nocopy JTF_VARCHAR2_TABLE_100
    , p7_a44 out nocopy JTF_DATE_TABLE
    , p7_a45 out nocopy JTF_NUMBER_TABLE
    , p7_a46 out nocopy JTF_VARCHAR2_TABLE_100
    , p7_a47 out nocopy JTF_DATE_TABLE
    , p7_a48 out nocopy JTF_NUMBER_TABLE
    , p7_a49 out nocopy JTF_VARCHAR2_TABLE_100
    , p7_a50 out nocopy JTF_DATE_TABLE
    , p7_a51 out nocopy JTF_NUMBER_TABLE
    , p7_a52 out nocopy JTF_VARCHAR2_TABLE_100
    , p7_a53 out nocopy JTF_DATE_TABLE
    , p7_a54 out nocopy JTF_NUMBER_TABLE
    , p7_a55 out nocopy JTF_VARCHAR2_TABLE_100
    , p7_a56 out nocopy JTF_DATE_TABLE
    , p7_a57 out nocopy JTF_NUMBER_TABLE
    , p7_a58 out nocopy JTF_VARCHAR2_TABLE_100
    , p7_a59 out nocopy JTF_DATE_TABLE
    , p7_a60 out nocopy JTF_NUMBER_TABLE
    , p7_a61 out nocopy JTF_VARCHAR2_TABLE_100
    , p7_a62 out nocopy JTF_DATE_TABLE
    , p7_a63 out nocopy JTF_NUMBER_TABLE
    , p7_a64 out nocopy JTF_VARCHAR2_TABLE_100
    , p7_a65 out nocopy JTF_DATE_TABLE
    , p7_a66 out nocopy JTF_NUMBER_TABLE
    , p7_a67 out nocopy JTF_VARCHAR2_TABLE_100
    , p7_a68 out nocopy JTF_DATE_TABLE
    , p7_a69 out nocopy JTF_NUMBER_TABLE
    , p7_a70 out nocopy JTF_NUMBER_TABLE
  )

  as
    ddp_org_sch_search_rec ahl_amp_workbench_pvt.org_sch_search_rec;
    ddx_sch_graph_results_tbl ahl_amp_workbench_pvt.sch_graph_results_tbl;
    ddindx binary_integer; indx binary_integer;
  begin

    -- copy data to the local IN or IN-OUT args, if any






    ddp_org_sch_search_rec.org_id := p6_a0;
    ddp_org_sch_search_rec.department_id := p6_a1;
    ddp_org_sch_search_rec.space_id := p6_a2;
    ddp_org_sch_search_rec.department_name := p6_a3;
    ddp_org_sch_search_rec.space_name := p6_a4;
    ddp_org_sch_search_rec.start_from_date := p6_a5;
    ddp_org_sch_search_rec.start_before_date := p6_a6;
    ddp_org_sch_search_rec.display_window := p6_a7;
    ddp_org_sch_search_rec.result_filter := p6_a8;


    -- here's the delegated call to the old PL/SQL routine
    ahl_amp_workbench_pvt.get_org_sch_graph(p_api_version,
      p_init_msg_list,
      p_validation_level,
      x_return_status,
      x_msg_count,
      x_msg_data,
      ddp_org_sch_search_rec,
      ddx_sch_graph_results_tbl);

    -- copy data back from the local variables to OUT or IN-OUT args, if any







    ahl_amp_workbench_pvt_w.rosetta_table_copy_out_p6(ddx_sch_graph_results_tbl, p7_a0
      , p7_a1
      , p7_a2
      , p7_a3
      , p7_a4
      , p7_a5
      , p7_a6
      , p7_a7
      , p7_a8
      , p7_a9
      , p7_a10
      , p7_a11
      , p7_a12
      , p7_a13
      , p7_a14
      , p7_a15
      , p7_a16
      , p7_a17
      , p7_a18
      , p7_a19
      , p7_a20
      , p7_a21
      , p7_a22
      , p7_a23
      , p7_a24
      , p7_a25
      , p7_a26
      , p7_a27
      , p7_a28
      , p7_a29
      , p7_a30
      , p7_a31
      , p7_a32
      , p7_a33
      , p7_a34
      , p7_a35
      , p7_a36
      , p7_a37
      , p7_a38
      , p7_a39
      , p7_a40
      , p7_a41
      , p7_a42
      , p7_a43
      , p7_a44
      , p7_a45
      , p7_a46
      , p7_a47
      , p7_a48
      , p7_a49
      , p7_a50
      , p7_a51
      , p7_a52
      , p7_a53
      , p7_a54
      , p7_a55
      , p7_a56
      , p7_a57
      , p7_a58
      , p7_a59
      , p7_a60
      , p7_a61
      , p7_a62
      , p7_a63
      , p7_a64
      , p7_a65
      , p7_a66
      , p7_a67
      , p7_a68
      , p7_a69
      , p7_a70
      );
  end;

  procedure get_visits_for_date_org(p_api_version  NUMBER
    , p_init_msg_list  VARCHAR2
    , p_validation_level  NUMBER
    , x_return_status out nocopy  VARCHAR2
    , x_msg_count out nocopy  NUMBER
    , x_msg_data out nocopy  VARCHAR2
    , p6_a0  NUMBER
    , p6_a1  NUMBER
    , p6_a2  NUMBER
    , p6_a3  VARCHAR2
    , p6_a4  VARCHAR2
    , p6_a5  DATE
    , p6_a6  DATE
    , p6_a7  NUMBER
    , p6_a8  VARCHAR2
    , p7_a0 out nocopy  NUMBER
    , p7_a1 out nocopy  NUMBER
    , p7_a2 out nocopy  VARCHAR2
    , p7_a3 out nocopy  NUMBER
    , p7_a4 out nocopy  VARCHAR2
    , p7_a5 out nocopy  NUMBER
    , p7_a6 out nocopy  VARCHAR2
    , p7_a7 out nocopy  VARCHAR2
    , p7_a8 out nocopy  DATE
    , p7_a9 out nocopy  NUMBER
    , p7_a10 out nocopy  VARCHAR2
    , p7_a11 out nocopy  DATE
    , p7_a12 out nocopy  NUMBER
    , p7_a13 out nocopy  VARCHAR2
    , p7_a14 out nocopy  DATE
    , p7_a15 out nocopy  NUMBER
    , p7_a16 out nocopy  VARCHAR2
    , p7_a17 out nocopy  DATE
    , p7_a18 out nocopy  NUMBER
    , p7_a19 out nocopy  VARCHAR2
    , p7_a20 out nocopy  DATE
    , p7_a21 out nocopy  NUMBER
    , p7_a22 out nocopy  VARCHAR2
    , p7_a23 out nocopy  DATE
    , p7_a24 out nocopy  NUMBER
    , p7_a25 out nocopy  VARCHAR2
    , p7_a26 out nocopy  DATE
    , p7_a27 out nocopy  NUMBER
    , p7_a28 out nocopy  VARCHAR2
    , p7_a29 out nocopy  DATE
    , p7_a30 out nocopy  NUMBER
    , p7_a31 out nocopy  VARCHAR2
    , p7_a32 out nocopy  DATE
    , p7_a33 out nocopy  NUMBER
    , p7_a34 out nocopy  VARCHAR2
    , p7_a35 out nocopy  DATE
    , p7_a36 out nocopy  NUMBER
    , p7_a37 out nocopy  VARCHAR2
    , p7_a38 out nocopy  DATE
    , p7_a39 out nocopy  NUMBER
    , p7_a40 out nocopy  VARCHAR2
    , p7_a41 out nocopy  DATE
    , p7_a42 out nocopy  NUMBER
    , p7_a43 out nocopy  VARCHAR2
    , p7_a44 out nocopy  DATE
    , p7_a45 out nocopy  NUMBER
    , p7_a46 out nocopy  VARCHAR2
    , p7_a47 out nocopy  DATE
    , p7_a48 out nocopy  NUMBER
    , p7_a49 out nocopy  VARCHAR2
    , p7_a50 out nocopy  DATE
    , p7_a51 out nocopy  NUMBER
    , p7_a52 out nocopy  VARCHAR2
    , p7_a53 out nocopy  DATE
    , p7_a54 out nocopy  NUMBER
    , p7_a55 out nocopy  VARCHAR2
    , p7_a56 out nocopy  DATE
    , p7_a57 out nocopy  NUMBER
    , p7_a58 out nocopy  VARCHAR2
    , p7_a59 out nocopy  DATE
    , p7_a60 out nocopy  NUMBER
    , p7_a61 out nocopy  VARCHAR2
    , p7_a62 out nocopy  DATE
    , p7_a63 out nocopy  NUMBER
    , p7_a64 out nocopy  VARCHAR2
    , p7_a65 out nocopy  DATE
    , p7_a66 out nocopy  NUMBER
    , p7_a67 out nocopy  VARCHAR2
    , p7_a68 out nocopy  DATE
    , p7_a69 out nocopy  NUMBER
    , p7_a70 out nocopy  NUMBER
    , p8_a0 out nocopy JTF_NUMBER_TABLE
    , p8_a1 out nocopy JTF_DATE_TABLE
    , p8_a2 out nocopy JTF_DATE_TABLE
  )

  as
    ddp_org_sch_search_rec ahl_amp_workbench_pvt.org_sch_search_rec;
    ddx_sch_graph_rec ahl_amp_workbench_pvt.sch_graph_results_rec;
    ddx_sch_visits_tbl ahl_amp_workbench_pvt.sch_visits_tbl;
    ddindx binary_integer; indx binary_integer;
  begin

    -- copy data to the local IN or IN-OUT args, if any






    ddp_org_sch_search_rec.org_id := p6_a0;
    ddp_org_sch_search_rec.department_id := p6_a1;
    ddp_org_sch_search_rec.space_id := p6_a2;
    ddp_org_sch_search_rec.department_name := p6_a3;
    ddp_org_sch_search_rec.space_name := p6_a4;
    ddp_org_sch_search_rec.start_from_date := p6_a5;
    ddp_org_sch_search_rec.start_before_date := p6_a6;
    ddp_org_sch_search_rec.display_window := p6_a7;
    ddp_org_sch_search_rec.result_filter := p6_a8;



    -- here's the delegated call to the old PL/SQL routine
    ahl_amp_workbench_pvt.get_visits_for_date_org(p_api_version,
      p_init_msg_list,
      p_validation_level,
      x_return_status,
      x_msg_count,
      x_msg_data,
      ddp_org_sch_search_rec,
      ddx_sch_graph_rec,
      ddx_sch_visits_tbl);

    -- copy data back from the local variables to OUT or IN-OUT args, if any







    p7_a0 := ddx_sch_graph_rec.org_id;
    p7_a1 := ddx_sch_graph_rec.department_id;
    p7_a2 := ddx_sch_graph_rec.department_desc;
    p7_a3 := ddx_sch_graph_rec.space_id;
    p7_a4 := ddx_sch_graph_rec.space_name;
    p7_a5 := ddx_sch_graph_rec.unit_id;
    p7_a6 := ddx_sch_graph_rec.unit_name;
    p7_a7 := ddx_sch_graph_rec.schedule_type_1;
    p7_a8 := ddx_sch_graph_rec.visit_date_1;
    p7_a9 := ddx_sch_graph_rec.visit_id_1;
    p7_a10 := ddx_sch_graph_rec.schedule_type_2;
    p7_a11 := ddx_sch_graph_rec.visit_date_2;
    p7_a12 := ddx_sch_graph_rec.visit_id_2;
    p7_a13 := ddx_sch_graph_rec.schedule_type_3;
    p7_a14 := ddx_sch_graph_rec.visit_date_3;
    p7_a15 := ddx_sch_graph_rec.visit_id_3;
    p7_a16 := ddx_sch_graph_rec.schedule_type_4;
    p7_a17 := ddx_sch_graph_rec.visit_date_4;
    p7_a18 := ddx_sch_graph_rec.visit_id_4;
    p7_a19 := ddx_sch_graph_rec.schedule_type_5;
    p7_a20 := ddx_sch_graph_rec.visit_date_5;
    p7_a21 := ddx_sch_graph_rec.visit_id_5;
    p7_a22 := ddx_sch_graph_rec.schedule_type_6;
    p7_a23 := ddx_sch_graph_rec.visit_date_6;
    p7_a24 := ddx_sch_graph_rec.visit_id_6;
    p7_a25 := ddx_sch_graph_rec.schedule_type_7;
    p7_a26 := ddx_sch_graph_rec.visit_date_7;
    p7_a27 := ddx_sch_graph_rec.visit_id_7;
    p7_a28 := ddx_sch_graph_rec.schedule_type_8;
    p7_a29 := ddx_sch_graph_rec.visit_date_8;
    p7_a30 := ddx_sch_graph_rec.visit_id_8;
    p7_a31 := ddx_sch_graph_rec.schedule_type_9;
    p7_a32 := ddx_sch_graph_rec.visit_date_9;
    p7_a33 := ddx_sch_graph_rec.visit_id_9;
    p7_a34 := ddx_sch_graph_rec.schedule_type_10;
    p7_a35 := ddx_sch_graph_rec.visit_date_10;
    p7_a36 := ddx_sch_graph_rec.visit_id_10;
    p7_a37 := ddx_sch_graph_rec.schedule_type_11;
    p7_a38 := ddx_sch_graph_rec.visit_date_11;
    p7_a39 := ddx_sch_graph_rec.visit_id_11;
    p7_a40 := ddx_sch_graph_rec.schedule_type_12;
    p7_a41 := ddx_sch_graph_rec.visit_date_12;
    p7_a42 := ddx_sch_graph_rec.visit_id_12;
    p7_a43 := ddx_sch_graph_rec.schedule_type_13;
    p7_a44 := ddx_sch_graph_rec.visit_date_13;
    p7_a45 := ddx_sch_graph_rec.visit_id_13;
    p7_a46 := ddx_sch_graph_rec.schedule_type_14;
    p7_a47 := ddx_sch_graph_rec.visit_date_14;
    p7_a48 := ddx_sch_graph_rec.visit_id_14;
    p7_a49 := ddx_sch_graph_rec.schedule_type_15;
    p7_a50 := ddx_sch_graph_rec.visit_date_15;
    p7_a51 := ddx_sch_graph_rec.visit_id_15;
    p7_a52 := ddx_sch_graph_rec.schedule_type_16;
    p7_a53 := ddx_sch_graph_rec.visit_date_16;
    p7_a54 := ddx_sch_graph_rec.visit_id_16;
    p7_a55 := ddx_sch_graph_rec.schedule_type_17;
    p7_a56 := ddx_sch_graph_rec.visit_date_17;
    p7_a57 := ddx_sch_graph_rec.visit_id_17;
    p7_a58 := ddx_sch_graph_rec.schedule_type_18;
    p7_a59 := ddx_sch_graph_rec.visit_date_18;
    p7_a60 := ddx_sch_graph_rec.visit_id_18;
    p7_a61 := ddx_sch_graph_rec.schedule_type_19;
    p7_a62 := ddx_sch_graph_rec.visit_date_19;
    p7_a63 := ddx_sch_graph_rec.visit_id_19;
    p7_a64 := ddx_sch_graph_rec.schedule_type_20;
    p7_a65 := ddx_sch_graph_rec.visit_date_20;
    p7_a66 := ddx_sch_graph_rec.visit_id_20;
    p7_a67 := ddx_sch_graph_rec.schedule_type_21;
    p7_a68 := ddx_sch_graph_rec.visit_date_21;
    p7_a69 := ddx_sch_graph_rec.visit_id_21;
    if ddx_sch_graph_rec.filter_rec is null
      then p7_a70 := null;
    elsif ddx_sch_graph_rec.filter_rec
      then p7_a70 := 1;
    else p7_a70 := 0;
    end if;

    ahl_amp_workbench_pvt_w.rosetta_table_copy_out_p7(ddx_sch_visits_tbl, p8_a0
      , p8_a1
      , p8_a2
      );
  end;

  procedure get_flt_sch_graph(p_api_version  NUMBER
    , p_init_msg_list  VARCHAR2
    , p_validation_level  NUMBER
    , x_return_status out nocopy  VARCHAR2
    , x_msg_count out nocopy  NUMBER
    , x_msg_data out nocopy  VARCHAR2
    , p6_a0  NUMBER
    , p6_a1  NUMBER
    , p6_a2  VARCHAR2
    , p6_a3  VARCHAR2
    , p6_a4  NUMBER
    , p6_a5  VARCHAR2
    , p6_a6  DATE
    , p6_a7  DATE
    , p6_a8  NUMBER
    , p7_a0 out nocopy JTF_NUMBER_TABLE
    , p7_a1 out nocopy JTF_NUMBER_TABLE
    , p7_a2 out nocopy JTF_VARCHAR2_TABLE_300
    , p7_a3 out nocopy JTF_NUMBER_TABLE
    , p7_a4 out nocopy JTF_VARCHAR2_TABLE_100
    , p7_a5 out nocopy JTF_NUMBER_TABLE
    , p7_a6 out nocopy JTF_VARCHAR2_TABLE_300
    , p7_a7 out nocopy JTF_VARCHAR2_TABLE_100
    , p7_a8 out nocopy JTF_DATE_TABLE
    , p7_a9 out nocopy JTF_NUMBER_TABLE
    , p7_a10 out nocopy JTF_VARCHAR2_TABLE_100
    , p7_a11 out nocopy JTF_DATE_TABLE
    , p7_a12 out nocopy JTF_NUMBER_TABLE
    , p7_a13 out nocopy JTF_VARCHAR2_TABLE_100
    , p7_a14 out nocopy JTF_DATE_TABLE
    , p7_a15 out nocopy JTF_NUMBER_TABLE
    , p7_a16 out nocopy JTF_VARCHAR2_TABLE_100
    , p7_a17 out nocopy JTF_DATE_TABLE
    , p7_a18 out nocopy JTF_NUMBER_TABLE
    , p7_a19 out nocopy JTF_VARCHAR2_TABLE_100
    , p7_a20 out nocopy JTF_DATE_TABLE
    , p7_a21 out nocopy JTF_NUMBER_TABLE
    , p7_a22 out nocopy JTF_VARCHAR2_TABLE_100
    , p7_a23 out nocopy JTF_DATE_TABLE
    , p7_a24 out nocopy JTF_NUMBER_TABLE
    , p7_a25 out nocopy JTF_VARCHAR2_TABLE_100
    , p7_a26 out nocopy JTF_DATE_TABLE
    , p7_a27 out nocopy JTF_NUMBER_TABLE
    , p7_a28 out nocopy JTF_VARCHAR2_TABLE_100
    , p7_a29 out nocopy JTF_DATE_TABLE
    , p7_a30 out nocopy JTF_NUMBER_TABLE
    , p7_a31 out nocopy JTF_VARCHAR2_TABLE_100
    , p7_a32 out nocopy JTF_DATE_TABLE
    , p7_a33 out nocopy JTF_NUMBER_TABLE
    , p7_a34 out nocopy JTF_VARCHAR2_TABLE_100
    , p7_a35 out nocopy JTF_DATE_TABLE
    , p7_a36 out nocopy JTF_NUMBER_TABLE
    , p7_a37 out nocopy JTF_VARCHAR2_TABLE_100
    , p7_a38 out nocopy JTF_DATE_TABLE
    , p7_a39 out nocopy JTF_NUMBER_TABLE
    , p7_a40 out nocopy JTF_VARCHAR2_TABLE_100
    , p7_a41 out nocopy JTF_DATE_TABLE
    , p7_a42 out nocopy JTF_NUMBER_TABLE
    , p7_a43 out nocopy JTF_VARCHAR2_TABLE_100
    , p7_a44 out nocopy JTF_DATE_TABLE
    , p7_a45 out nocopy JTF_NUMBER_TABLE
    , p7_a46 out nocopy JTF_VARCHAR2_TABLE_100
    , p7_a47 out nocopy JTF_DATE_TABLE
    , p7_a48 out nocopy JTF_NUMBER_TABLE
    , p7_a49 out nocopy JTF_VARCHAR2_TABLE_100
    , p7_a50 out nocopy JTF_DATE_TABLE
    , p7_a51 out nocopy JTF_NUMBER_TABLE
    , p7_a52 out nocopy JTF_VARCHAR2_TABLE_100
    , p7_a53 out nocopy JTF_DATE_TABLE
    , p7_a54 out nocopy JTF_NUMBER_TABLE
    , p7_a55 out nocopy JTF_VARCHAR2_TABLE_100
    , p7_a56 out nocopy JTF_DATE_TABLE
    , p7_a57 out nocopy JTF_NUMBER_TABLE
    , p7_a58 out nocopy JTF_VARCHAR2_TABLE_100
    , p7_a59 out nocopy JTF_DATE_TABLE
    , p7_a60 out nocopy JTF_NUMBER_TABLE
    , p7_a61 out nocopy JTF_VARCHAR2_TABLE_100
    , p7_a62 out nocopy JTF_DATE_TABLE
    , p7_a63 out nocopy JTF_NUMBER_TABLE
    , p7_a64 out nocopy JTF_VARCHAR2_TABLE_100
    , p7_a65 out nocopy JTF_DATE_TABLE
    , p7_a66 out nocopy JTF_NUMBER_TABLE
    , p7_a67 out nocopy JTF_VARCHAR2_TABLE_100
    , p7_a68 out nocopy JTF_DATE_TABLE
    , p7_a69 out nocopy JTF_NUMBER_TABLE
    , p7_a70 out nocopy JTF_NUMBER_TABLE
  )

  as
    ddp_flt_sch_search_rec ahl_amp_workbench_pvt.fleet_sch_search_rec;
    ddx_sch_graph_results_tbl ahl_amp_workbench_pvt.sch_graph_results_tbl;
    ddindx binary_integer; indx binary_integer;
  begin

    -- copy data to the local IN or IN-OUT args, if any






    ddp_flt_sch_search_rec.fleet_id := p6_a0;
    ddp_flt_sch_search_rec.unit_id := p6_a1;
    ddp_flt_sch_search_rec.unit_name := p6_a2;
    ddp_flt_sch_search_rec.master_config := p6_a3;
    ddp_flt_sch_search_rec.minimum_duration := p6_a4;
    ddp_flt_sch_search_rec.uom := p6_a5;
    ddp_flt_sch_search_rec.start_from_date := p6_a6;
    ddp_flt_sch_search_rec.start_before_date := p6_a7;
    ddp_flt_sch_search_rec.display_window := p6_a8;


    -- here's the delegated call to the old PL/SQL routine
    ahl_amp_workbench_pvt.get_flt_sch_graph(p_api_version,
      p_init_msg_list,
      p_validation_level,
      x_return_status,
      x_msg_count,
      x_msg_data,
      ddp_flt_sch_search_rec,
      ddx_sch_graph_results_tbl);

    -- copy data back from the local variables to OUT or IN-OUT args, if any







    ahl_amp_workbench_pvt_w.rosetta_table_copy_out_p6(ddx_sch_graph_results_tbl, p7_a0
      , p7_a1
      , p7_a2
      , p7_a3
      , p7_a4
      , p7_a5
      , p7_a6
      , p7_a7
      , p7_a8
      , p7_a9
      , p7_a10
      , p7_a11
      , p7_a12
      , p7_a13
      , p7_a14
      , p7_a15
      , p7_a16
      , p7_a17
      , p7_a18
      , p7_a19
      , p7_a20
      , p7_a21
      , p7_a22
      , p7_a23
      , p7_a24
      , p7_a25
      , p7_a26
      , p7_a27
      , p7_a28
      , p7_a29
      , p7_a30
      , p7_a31
      , p7_a32
      , p7_a33
      , p7_a34
      , p7_a35
      , p7_a36
      , p7_a37
      , p7_a38
      , p7_a39
      , p7_a40
      , p7_a41
      , p7_a42
      , p7_a43
      , p7_a44
      , p7_a45
      , p7_a46
      , p7_a47
      , p7_a48
      , p7_a49
      , p7_a50
      , p7_a51
      , p7_a52
      , p7_a53
      , p7_a54
      , p7_a55
      , p7_a56
      , p7_a57
      , p7_a58
      , p7_a59
      , p7_a60
      , p7_a61
      , p7_a62
      , p7_a63
      , p7_a64
      , p7_a65
      , p7_a66
      , p7_a67
      , p7_a68
      , p7_a69
      , p7_a70
      );
  end;

  procedure get_visits_for_date_flt(p_api_version  NUMBER
    , p_init_msg_list  VARCHAR2
    , p_validation_level  NUMBER
    , x_return_status out nocopy  VARCHAR2
    , x_msg_count out nocopy  NUMBER
    , x_msg_data out nocopy  VARCHAR2
    , p6_a0  NUMBER
    , p6_a1  NUMBER
    , p6_a2  VARCHAR2
    , p6_a3  VARCHAR2
    , p6_a4  NUMBER
    , p6_a5  VARCHAR2
    , p6_a6  DATE
    , p6_a7  DATE
    , p6_a8  NUMBER
    , p7_a0 out nocopy  NUMBER
    , p7_a1 out nocopy  NUMBER
    , p7_a2 out nocopy  VARCHAR2
    , p7_a3 out nocopy  NUMBER
    , p7_a4 out nocopy  VARCHAR2
    , p7_a5 out nocopy  NUMBER
    , p7_a6 out nocopy  VARCHAR2
    , p7_a7 out nocopy  VARCHAR2
    , p7_a8 out nocopy  DATE
    , p7_a9 out nocopy  NUMBER
    , p7_a10 out nocopy  VARCHAR2
    , p7_a11 out nocopy  DATE
    , p7_a12 out nocopy  NUMBER
    , p7_a13 out nocopy  VARCHAR2
    , p7_a14 out nocopy  DATE
    , p7_a15 out nocopy  NUMBER
    , p7_a16 out nocopy  VARCHAR2
    , p7_a17 out nocopy  DATE
    , p7_a18 out nocopy  NUMBER
    , p7_a19 out nocopy  VARCHAR2
    , p7_a20 out nocopy  DATE
    , p7_a21 out nocopy  NUMBER
    , p7_a22 out nocopy  VARCHAR2
    , p7_a23 out nocopy  DATE
    , p7_a24 out nocopy  NUMBER
    , p7_a25 out nocopy  VARCHAR2
    , p7_a26 out nocopy  DATE
    , p7_a27 out nocopy  NUMBER
    , p7_a28 out nocopy  VARCHAR2
    , p7_a29 out nocopy  DATE
    , p7_a30 out nocopy  NUMBER
    , p7_a31 out nocopy  VARCHAR2
    , p7_a32 out nocopy  DATE
    , p7_a33 out nocopy  NUMBER
    , p7_a34 out nocopy  VARCHAR2
    , p7_a35 out nocopy  DATE
    , p7_a36 out nocopy  NUMBER
    , p7_a37 out nocopy  VARCHAR2
    , p7_a38 out nocopy  DATE
    , p7_a39 out nocopy  NUMBER
    , p7_a40 out nocopy  VARCHAR2
    , p7_a41 out nocopy  DATE
    , p7_a42 out nocopy  NUMBER
    , p7_a43 out nocopy  VARCHAR2
    , p7_a44 out nocopy  DATE
    , p7_a45 out nocopy  NUMBER
    , p7_a46 out nocopy  VARCHAR2
    , p7_a47 out nocopy  DATE
    , p7_a48 out nocopy  NUMBER
    , p7_a49 out nocopy  VARCHAR2
    , p7_a50 out nocopy  DATE
    , p7_a51 out nocopy  NUMBER
    , p7_a52 out nocopy  VARCHAR2
    , p7_a53 out nocopy  DATE
    , p7_a54 out nocopy  NUMBER
    , p7_a55 out nocopy  VARCHAR2
    , p7_a56 out nocopy  DATE
    , p7_a57 out nocopy  NUMBER
    , p7_a58 out nocopy  VARCHAR2
    , p7_a59 out nocopy  DATE
    , p7_a60 out nocopy  NUMBER
    , p7_a61 out nocopy  VARCHAR2
    , p7_a62 out nocopy  DATE
    , p7_a63 out nocopy  NUMBER
    , p7_a64 out nocopy  VARCHAR2
    , p7_a65 out nocopy  DATE
    , p7_a66 out nocopy  NUMBER
    , p7_a67 out nocopy  VARCHAR2
    , p7_a68 out nocopy  DATE
    , p7_a69 out nocopy  NUMBER
    , p7_a70 out nocopy  NUMBER
    , p8_a0 out nocopy JTF_NUMBER_TABLE
    , p8_a1 out nocopy JTF_DATE_TABLE
    , p8_a2 out nocopy JTF_DATE_TABLE
  )

  as
    ddp_flt_sch_search_rec ahl_amp_workbench_pvt.fleet_sch_search_rec;
    ddx_sch_graph_rec ahl_amp_workbench_pvt.sch_graph_results_rec;
    ddx_sch_visits_tbl ahl_amp_workbench_pvt.sch_visits_tbl;
    ddindx binary_integer; indx binary_integer;
  begin

    -- copy data to the local IN or IN-OUT args, if any






    ddp_flt_sch_search_rec.fleet_id := p6_a0;
    ddp_flt_sch_search_rec.unit_id := p6_a1;
    ddp_flt_sch_search_rec.unit_name := p6_a2;
    ddp_flt_sch_search_rec.master_config := p6_a3;
    ddp_flt_sch_search_rec.minimum_duration := p6_a4;
    ddp_flt_sch_search_rec.uom := p6_a5;
    ddp_flt_sch_search_rec.start_from_date := p6_a6;
    ddp_flt_sch_search_rec.start_before_date := p6_a7;
    ddp_flt_sch_search_rec.display_window := p6_a8;



    -- here's the delegated call to the old PL/SQL routine
    ahl_amp_workbench_pvt.get_visits_for_date_flt(p_api_version,
      p_init_msg_list,
      p_validation_level,
      x_return_status,
      x_msg_count,
      x_msg_data,
      ddp_flt_sch_search_rec,
      ddx_sch_graph_rec,
      ddx_sch_visits_tbl);

    -- copy data back from the local variables to OUT or IN-OUT args, if any







    p7_a0 := ddx_sch_graph_rec.org_id;
    p7_a1 := ddx_sch_graph_rec.department_id;
    p7_a2 := ddx_sch_graph_rec.department_desc;
    p7_a3 := ddx_sch_graph_rec.space_id;
    p7_a4 := ddx_sch_graph_rec.space_name;
    p7_a5 := ddx_sch_graph_rec.unit_id;
    p7_a6 := ddx_sch_graph_rec.unit_name;
    p7_a7 := ddx_sch_graph_rec.schedule_type_1;
    p7_a8 := ddx_sch_graph_rec.visit_date_1;
    p7_a9 := ddx_sch_graph_rec.visit_id_1;
    p7_a10 := ddx_sch_graph_rec.schedule_type_2;
    p7_a11 := ddx_sch_graph_rec.visit_date_2;
    p7_a12 := ddx_sch_graph_rec.visit_id_2;
    p7_a13 := ddx_sch_graph_rec.schedule_type_3;
    p7_a14 := ddx_sch_graph_rec.visit_date_3;
    p7_a15 := ddx_sch_graph_rec.visit_id_3;
    p7_a16 := ddx_sch_graph_rec.schedule_type_4;
    p7_a17 := ddx_sch_graph_rec.visit_date_4;
    p7_a18 := ddx_sch_graph_rec.visit_id_4;
    p7_a19 := ddx_sch_graph_rec.schedule_type_5;
    p7_a20 := ddx_sch_graph_rec.visit_date_5;
    p7_a21 := ddx_sch_graph_rec.visit_id_5;
    p7_a22 := ddx_sch_graph_rec.schedule_type_6;
    p7_a23 := ddx_sch_graph_rec.visit_date_6;
    p7_a24 := ddx_sch_graph_rec.visit_id_6;
    p7_a25 := ddx_sch_graph_rec.schedule_type_7;
    p7_a26 := ddx_sch_graph_rec.visit_date_7;
    p7_a27 := ddx_sch_graph_rec.visit_id_7;
    p7_a28 := ddx_sch_graph_rec.schedule_type_8;
    p7_a29 := ddx_sch_graph_rec.visit_date_8;
    p7_a30 := ddx_sch_graph_rec.visit_id_8;
    p7_a31 := ddx_sch_graph_rec.schedule_type_9;
    p7_a32 := ddx_sch_graph_rec.visit_date_9;
    p7_a33 := ddx_sch_graph_rec.visit_id_9;
    p7_a34 := ddx_sch_graph_rec.schedule_type_10;
    p7_a35 := ddx_sch_graph_rec.visit_date_10;
    p7_a36 := ddx_sch_graph_rec.visit_id_10;
    p7_a37 := ddx_sch_graph_rec.schedule_type_11;
    p7_a38 := ddx_sch_graph_rec.visit_date_11;
    p7_a39 := ddx_sch_graph_rec.visit_id_11;
    p7_a40 := ddx_sch_graph_rec.schedule_type_12;
    p7_a41 := ddx_sch_graph_rec.visit_date_12;
    p7_a42 := ddx_sch_graph_rec.visit_id_12;
    p7_a43 := ddx_sch_graph_rec.schedule_type_13;
    p7_a44 := ddx_sch_graph_rec.visit_date_13;
    p7_a45 := ddx_sch_graph_rec.visit_id_13;
    p7_a46 := ddx_sch_graph_rec.schedule_type_14;
    p7_a47 := ddx_sch_graph_rec.visit_date_14;
    p7_a48 := ddx_sch_graph_rec.visit_id_14;
    p7_a49 := ddx_sch_graph_rec.schedule_type_15;
    p7_a50 := ddx_sch_graph_rec.visit_date_15;
    p7_a51 := ddx_sch_graph_rec.visit_id_15;
    p7_a52 := ddx_sch_graph_rec.schedule_type_16;
    p7_a53 := ddx_sch_graph_rec.visit_date_16;
    p7_a54 := ddx_sch_graph_rec.visit_id_16;
    p7_a55 := ddx_sch_graph_rec.schedule_type_17;
    p7_a56 := ddx_sch_graph_rec.visit_date_17;
    p7_a57 := ddx_sch_graph_rec.visit_id_17;
    p7_a58 := ddx_sch_graph_rec.schedule_type_18;
    p7_a59 := ddx_sch_graph_rec.visit_date_18;
    p7_a60 := ddx_sch_graph_rec.visit_id_18;
    p7_a61 := ddx_sch_graph_rec.schedule_type_19;
    p7_a62 := ddx_sch_graph_rec.visit_date_19;
    p7_a63 := ddx_sch_graph_rec.visit_id_19;
    p7_a64 := ddx_sch_graph_rec.schedule_type_20;
    p7_a65 := ddx_sch_graph_rec.visit_date_20;
    p7_a66 := ddx_sch_graph_rec.visit_id_20;
    p7_a67 := ddx_sch_graph_rec.schedule_type_21;
    p7_a68 := ddx_sch_graph_rec.visit_date_21;
    p7_a69 := ddx_sch_graph_rec.visit_id_21;
    if ddx_sch_graph_rec.filter_rec is null
      then p7_a70 := null;
    elsif ddx_sch_graph_rec.filter_rec
      then p7_a70 := 1;
    else p7_a70 := 0;
    end if;

    ahl_amp_workbench_pvt_w.rosetta_table_copy_out_p7(ddx_sch_visits_tbl, p8_a0
      , p8_a1
      , p8_a2
      );
  end;

  procedure get_mc_graph_data(p_api_version  NUMBER
    , p_init_msg_list  VARCHAR2
    , p_commit  VARCHAR2
    , p_validation_level  NUMBER
    , p_default  VARCHAR2
    , p_module_type  VARCHAR2
    , x_return_status out nocopy  VARCHAR2
    , x_msg_count out nocopy  NUMBER
    , x_msg_data out nocopy  VARCHAR2
    , p_organization_id  NUMBER
    , p_department_id  NUMBER
    , p_start_date  DATE
    , p_no_of_days  NUMBER
    , p_max_range  NUMBER
    , p14_a0 in out nocopy JTF_NUMBER_TABLE
    , p14_a1 in out nocopy JTF_NUMBER_TABLE
    , p15_a0 in out nocopy JTF_DATE_TABLE
    , p15_a1 in out nocopy JTF_NUMBER_TABLE
    , p15_a2 in out nocopy JTF_NUMBER_TABLE
    , p15_a3 in out nocopy JTF_NUMBER_TABLE
    , p15_a4 in out nocopy JTF_NUMBER_TABLE
    , p15_a5 in out nocopy JTF_NUMBER_TABLE
    , p15_a6 in out nocopy JTF_NUMBER_TABLE
    , x_plan_date out nocopy  DATE
  )

  as
    ddp_x_resource_input ahl_amp_workbench_pvt.resource_input_tbl_type;
    ddp_x_resource_output ahl_amp_workbench_pvt.resource_output_tbl_type;
    ddindx binary_integer; indx binary_integer;
  begin

    -- copy data to the local IN or IN-OUT args, if any














    ahl_amp_workbench_pvt_w.rosetta_table_copy_in_p8(ddp_x_resource_input, p14_a0
      , p14_a1
      );

    ahl_amp_workbench_pvt_w.rosetta_table_copy_in_p9(ddp_x_resource_output, p15_a0
      , p15_a1
      , p15_a2
      , p15_a3
      , p15_a4
      , p15_a5
      , p15_a6
      );


    -- here's the delegated call to the old PL/SQL routine
    ahl_amp_workbench_pvt.get_mc_graph_data(p_api_version,
      p_init_msg_list,
      p_commit,
      p_validation_level,
      p_default,
      p_module_type,
      x_return_status,
      x_msg_count,
      x_msg_data,
      p_organization_id,
      p_department_id,
      p_start_date,
      p_no_of_days,
      p_max_range,
      ddp_x_resource_input,
      ddp_x_resource_output,
      x_plan_date);

    -- copy data back from the local variables to OUT or IN-OUT args, if any














    ahl_amp_workbench_pvt_w.rosetta_table_copy_out_p8(ddp_x_resource_input, p14_a0
      , p14_a1
      );

    ahl_amp_workbench_pvt_w.rosetta_table_copy_out_p9(ddp_x_resource_output, p15_a0
      , p15_a1
      , p15_a2
      , p15_a3
      , p15_a4
      , p15_a5
      , p15_a6
      );

  end;

end ahl_amp_workbench_pvt_w;
