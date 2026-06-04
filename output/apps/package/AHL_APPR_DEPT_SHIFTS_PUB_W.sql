
  CREATE OR REPLACE EDITIONABLE PACKAGE "APPS"."AHL_APPR_DEPT_SHIFTS_PUB_W" AUTHID CURRENT_USER as
  /* $Header: AHLWDSHS.pls 120.1.12020000.3 2015/01/31 11:21:40 bachandr ship $ */
  procedure create_appr_dept_shifts(p_api_version  NUMBER
    , p_init_msg_list  VARCHAR2
    , p_commit  VARCHAR2
    , p_validation_level  NUMBER
    , p_default  VARCHAR2
    , p_module_type  VARCHAR2
    , x_return_status out nocopy  VARCHAR2
    , x_msg_count out nocopy  NUMBER
    , x_msg_data out nocopy  VARCHAR2
    , p9_a0 in out nocopy  NUMBER
    , p9_a1 in out nocopy  NUMBER
    , p9_a2 in out nocopy  VARCHAR2
    , p9_a3 in out nocopy  NUMBER
    , p9_a4 in out nocopy  DATE
    , p9_a5 in out nocopy  NUMBER
    , p9_a6 in out nocopy  DATE
    , p9_a7 in out nocopy  NUMBER
    , p9_a8 in out nocopy  NUMBER
    , p9_a9 in out nocopy  NUMBER
    , p9_a10 in out nocopy  VARCHAR2
    , p9_a11 in out nocopy  VARCHAR2
    , p9_a12 in out nocopy  VARCHAR2
    , p9_a13 in out nocopy  NUMBER
    , p9_a14 in out nocopy  NUMBER
    , p9_a15 in out nocopy  NUMBER
    , p9_a16 in out nocopy  VARCHAR2
    , p9_a17 in out nocopy  VARCHAR2
    , p9_a18 in out nocopy  NUMBER
    , p9_a19 in out nocopy  VARCHAR2
    , p9_a20 in out nocopy  NUMBER
    , p9_a21 in out nocopy  VARCHAR2
    , p9_a22 in out nocopy  VARCHAR2
    , p9_a23 in out nocopy  VARCHAR2
    , p9_a24 in out nocopy  VARCHAR2
    , p9_a25 in out nocopy  VARCHAR2
    , p9_a26 in out nocopy  VARCHAR2
    , p9_a27 in out nocopy  VARCHAR2
    , p9_a28 in out nocopy  VARCHAR2
    , p9_a29 in out nocopy  VARCHAR2
    , p9_a30 in out nocopy  VARCHAR2
    , p9_a31 in out nocopy  VARCHAR2
    , p9_a32 in out nocopy  VARCHAR2
    , p9_a33 in out nocopy  VARCHAR2
    , p9_a34 in out nocopy  VARCHAR2
    , p9_a35 in out nocopy  VARCHAR2
    , p9_a36 in out nocopy  VARCHAR2
    , p9_a37 in out nocopy  VARCHAR2
    , p9_a38 in out nocopy  VARCHAR2
    , p9_a39 in out nocopy  NUMBER
    , p9_a40 in out nocopy  NUMBER
  );
  procedure delete_appr_dept_shifts(p_api_version  NUMBER
    , p_init_msg_list  VARCHAR2
    , p_commit  VARCHAR2
    , p_validation_level  NUMBER
    , p_default  VARCHAR2
    , p_module_type  VARCHAR2
    , x_return_status out nocopy  VARCHAR2
    , x_msg_count out nocopy  NUMBER
    , x_msg_data out nocopy  VARCHAR2
    , p9_a0 in out nocopy  NUMBER
    , p9_a1 in out nocopy  NUMBER
    , p9_a2 in out nocopy  VARCHAR2
    , p9_a3 in out nocopy  NUMBER
    , p9_a4 in out nocopy  DATE
    , p9_a5 in out nocopy  NUMBER
    , p9_a6 in out nocopy  DATE
    , p9_a7 in out nocopy  NUMBER
    , p9_a8 in out nocopy  NUMBER
    , p9_a9 in out nocopy  NUMBER
    , p9_a10 in out nocopy  VARCHAR2
    , p9_a11 in out nocopy  VARCHAR2
    , p9_a12 in out nocopy  VARCHAR2
    , p9_a13 in out nocopy  NUMBER
    , p9_a14 in out nocopy  NUMBER
    , p9_a15 in out nocopy  NUMBER
    , p9_a16 in out nocopy  VARCHAR2
    , p9_a17 in out nocopy  VARCHAR2
    , p9_a18 in out nocopy  NUMBER
    , p9_a19 in out nocopy  VARCHAR2
    , p9_a20 in out nocopy  NUMBER
    , p9_a21 in out nocopy  VARCHAR2
    , p9_a22 in out nocopy  VARCHAR2
    , p9_a23 in out nocopy  VARCHAR2
    , p9_a24 in out nocopy  VARCHAR2
    , p9_a25 in out nocopy  VARCHAR2
    , p9_a26 in out nocopy  VARCHAR2
    , p9_a27 in out nocopy  VARCHAR2
    , p9_a28 in out nocopy  VARCHAR2
    , p9_a29 in out nocopy  VARCHAR2
    , p9_a30 in out nocopy  VARCHAR2
    , p9_a31 in out nocopy  VARCHAR2
    , p9_a32 in out nocopy  VARCHAR2
    , p9_a33 in out nocopy  VARCHAR2
    , p9_a34 in out nocopy  VARCHAR2
    , p9_a35 in out nocopy  VARCHAR2
    , p9_a36 in out nocopy  VARCHAR2
    , p9_a37 in out nocopy  VARCHAR2
    , p9_a38 in out nocopy  VARCHAR2
    , p9_a39 in out nocopy  NUMBER
    , p9_a40 in out nocopy  NUMBER
  );
  procedure edit_appr_dept_shifts(p_api_version  NUMBER
    , p_init_msg_list  VARCHAR2
    , p_commit  VARCHAR2
    , p_validation_level  NUMBER
    , p_default  VARCHAR2
    , p_module_type  VARCHAR2
    , x_return_status out nocopy  VARCHAR2
    , x_msg_count out nocopy  NUMBER
    , x_msg_data out nocopy  VARCHAR2
    , p9_a0 in out nocopy  NUMBER
    , p9_a1 in out nocopy  NUMBER
    , p9_a2 in out nocopy  VARCHAR2
    , p9_a3 in out nocopy  NUMBER
    , p9_a4 in out nocopy  DATE
    , p9_a5 in out nocopy  NUMBER
    , p9_a6 in out nocopy  DATE
    , p9_a7 in out nocopy  NUMBER
    , p9_a8 in out nocopy  NUMBER
    , p9_a9 in out nocopy  NUMBER
    , p9_a10 in out nocopy  VARCHAR2
    , p9_a11 in out nocopy  VARCHAR2
    , p9_a12 in out nocopy  VARCHAR2
    , p9_a13 in out nocopy  NUMBER
    , p9_a14 in out nocopy  NUMBER
    , p9_a15 in out nocopy  NUMBER
    , p9_a16 in out nocopy  VARCHAR2
    , p9_a17 in out nocopy  VARCHAR2
    , p9_a18 in out nocopy  NUMBER
    , p9_a19 in out nocopy  VARCHAR2
    , p9_a20 in out nocopy  NUMBER
    , p9_a21 in out nocopy  VARCHAR2
    , p9_a22 in out nocopy  VARCHAR2
    , p9_a23 in out nocopy  VARCHAR2
    , p9_a24 in out nocopy  VARCHAR2
    , p9_a25 in out nocopy  VARCHAR2
    , p9_a26 in out nocopy  VARCHAR2
    , p9_a27 in out nocopy  VARCHAR2
    , p9_a28 in out nocopy  VARCHAR2
    , p9_a29 in out nocopy  VARCHAR2
    , p9_a30 in out nocopy  VARCHAR2
    , p9_a31 in out nocopy  VARCHAR2
    , p9_a32 in out nocopy  VARCHAR2
    , p9_a33 in out nocopy  VARCHAR2
    , p9_a34 in out nocopy  VARCHAR2
    , p9_a35 in out nocopy  VARCHAR2
    , p9_a36 in out nocopy  VARCHAR2
    , p9_a37 in out nocopy  VARCHAR2
    , p9_a38 in out nocopy  VARCHAR2
    , p9_a39 in out nocopy  NUMBER
    , p9_a40 in out nocopy  NUMBER
  );
end ahl_appr_dept_shifts_pub_w;

CREATE OR REPLACE EDITIONABLE PACKAGE BODY "APPS"."AHL_APPR_DEPT_SHIFTS_PUB_W" as
  /* $Header: AHLWDSHB.pls 120.2.12020000.3 2015/01/31 11:20:56 bachandr ship $ */
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

  procedure create_appr_dept_shifts(p_api_version  NUMBER
    , p_init_msg_list  VARCHAR2
    , p_commit  VARCHAR2
    , p_validation_level  NUMBER
    , p_default  VARCHAR2
    , p_module_type  VARCHAR2
    , x_return_status out nocopy  VARCHAR2
    , x_msg_count out nocopy  NUMBER
    , x_msg_data out nocopy  VARCHAR2
    , p9_a0 in out nocopy  NUMBER
    , p9_a1 in out nocopy  NUMBER
    , p9_a2 in out nocopy  VARCHAR2
    , p9_a3 in out nocopy  NUMBER
    , p9_a4 in out nocopy  DATE
    , p9_a5 in out nocopy  NUMBER
    , p9_a6 in out nocopy  DATE
    , p9_a7 in out nocopy  NUMBER
    , p9_a8 in out nocopy  NUMBER
    , p9_a9 in out nocopy  NUMBER
    , p9_a10 in out nocopy  VARCHAR2
    , p9_a11 in out nocopy  VARCHAR2
    , p9_a12 in out nocopy  VARCHAR2
    , p9_a13 in out nocopy  NUMBER
    , p9_a14 in out nocopy  NUMBER
    , p9_a15 in out nocopy  NUMBER
    , p9_a16 in out nocopy  VARCHAR2
    , p9_a17 in out nocopy  VARCHAR2
    , p9_a18 in out nocopy  NUMBER
    , p9_a19 in out nocopy  VARCHAR2
    , p9_a20 in out nocopy  NUMBER
    , p9_a21 in out nocopy  VARCHAR2
    , p9_a22 in out nocopy  VARCHAR2
    , p9_a23 in out nocopy  VARCHAR2
    , p9_a24 in out nocopy  VARCHAR2
    , p9_a25 in out nocopy  VARCHAR2
    , p9_a26 in out nocopy  VARCHAR2
    , p9_a27 in out nocopy  VARCHAR2
    , p9_a28 in out nocopy  VARCHAR2
    , p9_a29 in out nocopy  VARCHAR2
    , p9_a30 in out nocopy  VARCHAR2
    , p9_a31 in out nocopy  VARCHAR2
    , p9_a32 in out nocopy  VARCHAR2
    , p9_a33 in out nocopy  VARCHAR2
    , p9_a34 in out nocopy  VARCHAR2
    , p9_a35 in out nocopy  VARCHAR2
    , p9_a36 in out nocopy  VARCHAR2
    , p9_a37 in out nocopy  VARCHAR2
    , p9_a38 in out nocopy  VARCHAR2
    , p9_a39 in out nocopy  NUMBER
    , p9_a40 in out nocopy  NUMBER
  )

  as
    ddp_x_appr_deptshift_rec ahl_appr_dept_shifts_pub.appr_deptshift_rec;
    ddindx binary_integer; indx binary_integer;
  begin

    -- copy data to the local IN or IN-OUT args, if any









    ddp_x_appr_deptshift_rec.ahl_department_shifts_id := p9_a0;
    ddp_x_appr_deptshift_rec.organization_id := p9_a1;
    ddp_x_appr_deptshift_rec.organization_name := p9_a2;
    ddp_x_appr_deptshift_rec.object_version_number := p9_a3;
    ddp_x_appr_deptshift_rec.last_update_date := rosetta_g_miss_date_in_map(p9_a4);
    ddp_x_appr_deptshift_rec.last_updated_by := p9_a5;
    ddp_x_appr_deptshift_rec.creation_date := rosetta_g_miss_date_in_map(p9_a6);
    ddp_x_appr_deptshift_rec.created_by := p9_a7;
    ddp_x_appr_deptshift_rec.last_update_login := p9_a8;
    ddp_x_appr_deptshift_rec.department_id := p9_a9;
    ddp_x_appr_deptshift_rec.dept_description := p9_a10;
    ddp_x_appr_deptshift_rec.calendar_code := p9_a11;
    ddp_x_appr_deptshift_rec.calendar_description := p9_a12;
    ddp_x_appr_deptshift_rec.bom_workday_patterns_id := p9_a13;
    ddp_x_appr_deptshift_rec.shift_num := p9_a14;
    ddp_x_appr_deptshift_rec.seq_num := p9_a15;
    ddp_x_appr_deptshift_rec.seq_name := p9_a16;
    ddp_x_appr_deptshift_rec.subinventory := p9_a17;
    ddp_x_appr_deptshift_rec.inv_locator_id := p9_a18;
    ddp_x_appr_deptshift_rec.locator_segments := p9_a19;
    ddp_x_appr_deptshift_rec.max_service_category := p9_a20;
    ddp_x_appr_deptshift_rec.description := p9_a21;
    ddp_x_appr_deptshift_rec.attribute_category := p9_a22;
    ddp_x_appr_deptshift_rec.attribute1 := p9_a23;
    ddp_x_appr_deptshift_rec.attribute2 := p9_a24;
    ddp_x_appr_deptshift_rec.attribute3 := p9_a25;
    ddp_x_appr_deptshift_rec.attribute4 := p9_a26;
    ddp_x_appr_deptshift_rec.attribute5 := p9_a27;
    ddp_x_appr_deptshift_rec.attribute6 := p9_a28;
    ddp_x_appr_deptshift_rec.attribute7 := p9_a29;
    ddp_x_appr_deptshift_rec.attribute8 := p9_a30;
    ddp_x_appr_deptshift_rec.attribute9 := p9_a31;
    ddp_x_appr_deptshift_rec.attribute10 := p9_a32;
    ddp_x_appr_deptshift_rec.attribute11 := p9_a33;
    ddp_x_appr_deptshift_rec.attribute12 := p9_a34;
    ddp_x_appr_deptshift_rec.attribute13 := p9_a35;
    ddp_x_appr_deptshift_rec.attribute14 := p9_a36;
    ddp_x_appr_deptshift_rec.attribute15 := p9_a37;
    ddp_x_appr_deptshift_rec.dml_operation := p9_a38;
    ddp_x_appr_deptshift_rec.dept_latitude := p9_a39;
    ddp_x_appr_deptshift_rec.dept_longitude := p9_a40;

    -- here's the delegated call to the old PL/SQL routine
    ahl_appr_dept_shifts_pub.create_appr_dept_shifts(p_api_version,
      p_init_msg_list,
      p_commit,
      p_validation_level,
      p_default,
      p_module_type,
      x_return_status,
      x_msg_count,
      x_msg_data,
      ddp_x_appr_deptshift_rec);

    -- copy data back from the local variables to OUT or IN-OUT args, if any









    p9_a0 := ddp_x_appr_deptshift_rec.ahl_department_shifts_id;
    p9_a1 := ddp_x_appr_deptshift_rec.organization_id;
    p9_a2 := ddp_x_appr_deptshift_rec.organization_name;
    p9_a3 := ddp_x_appr_deptshift_rec.object_version_number;
    p9_a4 := ddp_x_appr_deptshift_rec.last_update_date;
    p9_a5 := ddp_x_appr_deptshift_rec.last_updated_by;
    p9_a6 := ddp_x_appr_deptshift_rec.creation_date;
    p9_a7 := ddp_x_appr_deptshift_rec.created_by;
    p9_a8 := ddp_x_appr_deptshift_rec.last_update_login;
    p9_a9 := ddp_x_appr_deptshift_rec.department_id;
    p9_a10 := ddp_x_appr_deptshift_rec.dept_description;
    p9_a11 := ddp_x_appr_deptshift_rec.calendar_code;
    p9_a12 := ddp_x_appr_deptshift_rec.calendar_description;
    p9_a13 := ddp_x_appr_deptshift_rec.bom_workday_patterns_id;
    p9_a14 := ddp_x_appr_deptshift_rec.shift_num;
    p9_a15 := ddp_x_appr_deptshift_rec.seq_num;
    p9_a16 := ddp_x_appr_deptshift_rec.seq_name;
    p9_a17 := ddp_x_appr_deptshift_rec.subinventory;
    p9_a18 := ddp_x_appr_deptshift_rec.inv_locator_id;
    p9_a19 := ddp_x_appr_deptshift_rec.locator_segments;
    p9_a20 := ddp_x_appr_deptshift_rec.max_service_category;
    p9_a21 := ddp_x_appr_deptshift_rec.description;
    p9_a22 := ddp_x_appr_deptshift_rec.attribute_category;
    p9_a23 := ddp_x_appr_deptshift_rec.attribute1;
    p9_a24 := ddp_x_appr_deptshift_rec.attribute2;
    p9_a25 := ddp_x_appr_deptshift_rec.attribute3;
    p9_a26 := ddp_x_appr_deptshift_rec.attribute4;
    p9_a27 := ddp_x_appr_deptshift_rec.attribute5;
    p9_a28 := ddp_x_appr_deptshift_rec.attribute6;
    p9_a29 := ddp_x_appr_deptshift_rec.attribute7;
    p9_a30 := ddp_x_appr_deptshift_rec.attribute8;
    p9_a31 := ddp_x_appr_deptshift_rec.attribute9;
    p9_a32 := ddp_x_appr_deptshift_rec.attribute10;
    p9_a33 := ddp_x_appr_deptshift_rec.attribute11;
    p9_a34 := ddp_x_appr_deptshift_rec.attribute12;
    p9_a35 := ddp_x_appr_deptshift_rec.attribute13;
    p9_a36 := ddp_x_appr_deptshift_rec.attribute14;
    p9_a37 := ddp_x_appr_deptshift_rec.attribute15;
    p9_a38 := ddp_x_appr_deptshift_rec.dml_operation;
    p9_a39 := ddp_x_appr_deptshift_rec.dept_latitude;
    p9_a40 := ddp_x_appr_deptshift_rec.dept_longitude;
  end;

  procedure delete_appr_dept_shifts(p_api_version  NUMBER
    , p_init_msg_list  VARCHAR2
    , p_commit  VARCHAR2
    , p_validation_level  NUMBER
    , p_default  VARCHAR2
    , p_module_type  VARCHAR2
    , x_return_status out nocopy  VARCHAR2
    , x_msg_count out nocopy  NUMBER
    , x_msg_data out nocopy  VARCHAR2
    , p9_a0 in out nocopy  NUMBER
    , p9_a1 in out nocopy  NUMBER
    , p9_a2 in out nocopy  VARCHAR2
    , p9_a3 in out nocopy  NUMBER
    , p9_a4 in out nocopy  DATE
    , p9_a5 in out nocopy  NUMBER
    , p9_a6 in out nocopy  DATE
    , p9_a7 in out nocopy  NUMBER
    , p9_a8 in out nocopy  NUMBER
    , p9_a9 in out nocopy  NUMBER
    , p9_a10 in out nocopy  VARCHAR2
    , p9_a11 in out nocopy  VARCHAR2
    , p9_a12 in out nocopy  VARCHAR2
    , p9_a13 in out nocopy  NUMBER
    , p9_a14 in out nocopy  NUMBER
    , p9_a15 in out nocopy  NUMBER
    , p9_a16 in out nocopy  VARCHAR2
    , p9_a17 in out nocopy  VARCHAR2
    , p9_a18 in out nocopy  NUMBER
    , p9_a19 in out nocopy  VARCHAR2
    , p9_a20 in out nocopy  NUMBER
    , p9_a21 in out nocopy  VARCHAR2
    , p9_a22 in out nocopy  VARCHAR2
    , p9_a23 in out nocopy  VARCHAR2
    , p9_a24 in out nocopy  VARCHAR2
    , p9_a25 in out nocopy  VARCHAR2
    , p9_a26 in out nocopy  VARCHAR2
    , p9_a27 in out nocopy  VARCHAR2
    , p9_a28 in out nocopy  VARCHAR2
    , p9_a29 in out nocopy  VARCHAR2
    , p9_a30 in out nocopy  VARCHAR2
    , p9_a31 in out nocopy  VARCHAR2
    , p9_a32 in out nocopy  VARCHAR2
    , p9_a33 in out nocopy  VARCHAR2
    , p9_a34 in out nocopy  VARCHAR2
    , p9_a35 in out nocopy  VARCHAR2
    , p9_a36 in out nocopy  VARCHAR2
    , p9_a37 in out nocopy  VARCHAR2
    , p9_a38 in out nocopy  VARCHAR2
    , p9_a39 in out nocopy  NUMBER
    , p9_a40 in out nocopy  NUMBER
  )

  as
    ddp_x_appr_deptshift_rec ahl_appr_dept_shifts_pub.appr_deptshift_rec;
    ddindx binary_integer; indx binary_integer;
  begin

    -- copy data to the local IN or IN-OUT args, if any









    ddp_x_appr_deptshift_rec.ahl_department_shifts_id := p9_a0;
    ddp_x_appr_deptshift_rec.organization_id := p9_a1;
    ddp_x_appr_deptshift_rec.organization_name := p9_a2;
    ddp_x_appr_deptshift_rec.object_version_number := p9_a3;
    ddp_x_appr_deptshift_rec.last_update_date := rosetta_g_miss_date_in_map(p9_a4);
    ddp_x_appr_deptshift_rec.last_updated_by := p9_a5;
    ddp_x_appr_deptshift_rec.creation_date := rosetta_g_miss_date_in_map(p9_a6);
    ddp_x_appr_deptshift_rec.created_by := p9_a7;
    ddp_x_appr_deptshift_rec.last_update_login := p9_a8;
    ddp_x_appr_deptshift_rec.department_id := p9_a9;
    ddp_x_appr_deptshift_rec.dept_description := p9_a10;
    ddp_x_appr_deptshift_rec.calendar_code := p9_a11;
    ddp_x_appr_deptshift_rec.calendar_description := p9_a12;
    ddp_x_appr_deptshift_rec.bom_workday_patterns_id := p9_a13;
    ddp_x_appr_deptshift_rec.shift_num := p9_a14;
    ddp_x_appr_deptshift_rec.seq_num := p9_a15;
    ddp_x_appr_deptshift_rec.seq_name := p9_a16;
    ddp_x_appr_deptshift_rec.subinventory := p9_a17;
    ddp_x_appr_deptshift_rec.inv_locator_id := p9_a18;
    ddp_x_appr_deptshift_rec.locator_segments := p9_a19;
    ddp_x_appr_deptshift_rec.max_service_category := p9_a20;
    ddp_x_appr_deptshift_rec.description := p9_a21;
    ddp_x_appr_deptshift_rec.attribute_category := p9_a22;
    ddp_x_appr_deptshift_rec.attribute1 := p9_a23;
    ddp_x_appr_deptshift_rec.attribute2 := p9_a24;
    ddp_x_appr_deptshift_rec.attribute3 := p9_a25;
    ddp_x_appr_deptshift_rec.attribute4 := p9_a26;
    ddp_x_appr_deptshift_rec.attribute5 := p9_a27;
    ddp_x_appr_deptshift_rec.attribute6 := p9_a28;
    ddp_x_appr_deptshift_rec.attribute7 := p9_a29;
    ddp_x_appr_deptshift_rec.attribute8 := p9_a30;
    ddp_x_appr_deptshift_rec.attribute9 := p9_a31;
    ddp_x_appr_deptshift_rec.attribute10 := p9_a32;
    ddp_x_appr_deptshift_rec.attribute11 := p9_a33;
    ddp_x_appr_deptshift_rec.attribute12 := p9_a34;
    ddp_x_appr_deptshift_rec.attribute13 := p9_a35;
    ddp_x_appr_deptshift_rec.attribute14 := p9_a36;
    ddp_x_appr_deptshift_rec.attribute15 := p9_a37;
    ddp_x_appr_deptshift_rec.dml_operation := p9_a38;
    ddp_x_appr_deptshift_rec.dept_latitude := p9_a39;
    ddp_x_appr_deptshift_rec.dept_longitude := p9_a40;

    -- here's the delegated call to the old PL/SQL routine
    ahl_appr_dept_shifts_pub.delete_appr_dept_shifts(p_api_version,
      p_init_msg_list,
      p_commit,
      p_validation_level,
      p_default,
      p_module_type,
      x_return_status,
      x_msg_count,
      x_msg_data,
      ddp_x_appr_deptshift_rec);

    -- copy data back from the local variables to OUT or IN-OUT args, if any









    p9_a0 := ddp_x_appr_deptshift_rec.ahl_department_shifts_id;
    p9_a1 := ddp_x_appr_deptshift_rec.organization_id;
    p9_a2 := ddp_x_appr_deptshift_rec.organization_name;
    p9_a3 := ddp_x_appr_deptshift_rec.object_version_number;
    p9_a4 := ddp_x_appr_deptshift_rec.last_update_date;
    p9_a5 := ddp_x_appr_deptshift_rec.last_updated_by;
    p9_a6 := ddp_x_appr_deptshift_rec.creation_date;
    p9_a7 := ddp_x_appr_deptshift_rec.created_by;
    p9_a8 := ddp_x_appr_deptshift_rec.last_update_login;
    p9_a9 := ddp_x_appr_deptshift_rec.department_id;
    p9_a10 := ddp_x_appr_deptshift_rec.dept_description;
    p9_a11 := ddp_x_appr_deptshift_rec.calendar_code;
    p9_a12 := ddp_x_appr_deptshift_rec.calendar_description;
    p9_a13 := ddp_x_appr_deptshift_rec.bom_workday_patterns_id;
    p9_a14 := ddp_x_appr_deptshift_rec.shift_num;
    p9_a15 := ddp_x_appr_deptshift_rec.seq_num;
    p9_a16 := ddp_x_appr_deptshift_rec.seq_name;
    p9_a17 := ddp_x_appr_deptshift_rec.subinventory;
    p9_a18 := ddp_x_appr_deptshift_rec.inv_locator_id;
    p9_a19 := ddp_x_appr_deptshift_rec.locator_segments;
    p9_a20 := ddp_x_appr_deptshift_rec.max_service_category;
    p9_a21 := ddp_x_appr_deptshift_rec.description;
    p9_a22 := ddp_x_appr_deptshift_rec.attribute_category;
    p9_a23 := ddp_x_appr_deptshift_rec.attribute1;
    p9_a24 := ddp_x_appr_deptshift_rec.attribute2;
    p9_a25 := ddp_x_appr_deptshift_rec.attribute3;
    p9_a26 := ddp_x_appr_deptshift_rec.attribute4;
    p9_a27 := ddp_x_appr_deptshift_rec.attribute5;
    p9_a28 := ddp_x_appr_deptshift_rec.attribute6;
    p9_a29 := ddp_x_appr_deptshift_rec.attribute7;
    p9_a30 := ddp_x_appr_deptshift_rec.attribute8;
    p9_a31 := ddp_x_appr_deptshift_rec.attribute9;
    p9_a32 := ddp_x_appr_deptshift_rec.attribute10;
    p9_a33 := ddp_x_appr_deptshift_rec.attribute11;
    p9_a34 := ddp_x_appr_deptshift_rec.attribute12;
    p9_a35 := ddp_x_appr_deptshift_rec.attribute13;
    p9_a36 := ddp_x_appr_deptshift_rec.attribute14;
    p9_a37 := ddp_x_appr_deptshift_rec.attribute15;
    p9_a38 := ddp_x_appr_deptshift_rec.dml_operation;
    p9_a39 := ddp_x_appr_deptshift_rec.dept_latitude;
    p9_a40 := ddp_x_appr_deptshift_rec.dept_longitude;
  end;

  procedure edit_appr_dept_shifts(p_api_version  NUMBER
    , p_init_msg_list  VARCHAR2
    , p_commit  VARCHAR2
    , p_validation_level  NUMBER
    , p_default  VARCHAR2
    , p_module_type  VARCHAR2
    , x_return_status out nocopy  VARCHAR2
    , x_msg_count out nocopy  NUMBER
    , x_msg_data out nocopy  VARCHAR2
    , p9_a0 in out nocopy  NUMBER
    , p9_a1 in out nocopy  NUMBER
    , p9_a2 in out nocopy  VARCHAR2
    , p9_a3 in out nocopy  NUMBER
    , p9_a4 in out nocopy  DATE
    , p9_a5 in out nocopy  NUMBER
    , p9_a6 in out nocopy  DATE
    , p9_a7 in out nocopy  NUMBER
    , p9_a8 in out nocopy  NUMBER
    , p9_a9 in out nocopy  NUMBER
    , p9_a10 in out nocopy  VARCHAR2
    , p9_a11 in out nocopy  VARCHAR2
    , p9_a12 in out nocopy  VARCHAR2
    , p9_a13 in out nocopy  NUMBER
    , p9_a14 in out nocopy  NUMBER
    , p9_a15 in out nocopy  NUMBER
    , p9_a16 in out nocopy  VARCHAR2
    , p9_a17 in out nocopy  VARCHAR2
    , p9_a18 in out nocopy  NUMBER
    , p9_a19 in out nocopy  VARCHAR2
    , p9_a20 in out nocopy  NUMBER
    , p9_a21 in out nocopy  VARCHAR2
    , p9_a22 in out nocopy  VARCHAR2
    , p9_a23 in out nocopy  VARCHAR2
    , p9_a24 in out nocopy  VARCHAR2
    , p9_a25 in out nocopy  VARCHAR2
    , p9_a26 in out nocopy  VARCHAR2
    , p9_a27 in out nocopy  VARCHAR2
    , p9_a28 in out nocopy  VARCHAR2
    , p9_a29 in out nocopy  VARCHAR2
    , p9_a30 in out nocopy  VARCHAR2
    , p9_a31 in out nocopy  VARCHAR2
    , p9_a32 in out nocopy  VARCHAR2
    , p9_a33 in out nocopy  VARCHAR2
    , p9_a34 in out nocopy  VARCHAR2
    , p9_a35 in out nocopy  VARCHAR2
    , p9_a36 in out nocopy  VARCHAR2
    , p9_a37 in out nocopy  VARCHAR2
    , p9_a38 in out nocopy  VARCHAR2
    , p9_a39 in out nocopy  NUMBER
    , p9_a40 in out nocopy  NUMBER
  )

  as
    ddp_x_appr_deptshift_rec ahl_appr_dept_shifts_pub.appr_deptshift_rec;
    ddindx binary_integer; indx binary_integer;
  begin

    -- copy data to the local IN or IN-OUT args, if any









    ddp_x_appr_deptshift_rec.ahl_department_shifts_id := p9_a0;
    ddp_x_appr_deptshift_rec.organization_id := p9_a1;
    ddp_x_appr_deptshift_rec.organization_name := p9_a2;
    ddp_x_appr_deptshift_rec.object_version_number := p9_a3;
    ddp_x_appr_deptshift_rec.last_update_date := rosetta_g_miss_date_in_map(p9_a4);
    ddp_x_appr_deptshift_rec.last_updated_by := p9_a5;
    ddp_x_appr_deptshift_rec.creation_date := rosetta_g_miss_date_in_map(p9_a6);
    ddp_x_appr_deptshift_rec.created_by := p9_a7;
    ddp_x_appr_deptshift_rec.last_update_login := p9_a8;
    ddp_x_appr_deptshift_rec.department_id := p9_a9;
    ddp_x_appr_deptshift_rec.dept_description := p9_a10;
    ddp_x_appr_deptshift_rec.calendar_code := p9_a11;
    ddp_x_appr_deptshift_rec.calendar_description := p9_a12;
    ddp_x_appr_deptshift_rec.bom_workday_patterns_id := p9_a13;
    ddp_x_appr_deptshift_rec.shift_num := p9_a14;
    ddp_x_appr_deptshift_rec.seq_num := p9_a15;
    ddp_x_appr_deptshift_rec.seq_name := p9_a16;
    ddp_x_appr_deptshift_rec.subinventory := p9_a17;
    ddp_x_appr_deptshift_rec.inv_locator_id := p9_a18;
    ddp_x_appr_deptshift_rec.locator_segments := p9_a19;
    ddp_x_appr_deptshift_rec.max_service_category := p9_a20;
    ddp_x_appr_deptshift_rec.description := p9_a21;
    ddp_x_appr_deptshift_rec.attribute_category := p9_a22;
    ddp_x_appr_deptshift_rec.attribute1 := p9_a23;
    ddp_x_appr_deptshift_rec.attribute2 := p9_a24;
    ddp_x_appr_deptshift_rec.attribute3 := p9_a25;
    ddp_x_appr_deptshift_rec.attribute4 := p9_a26;
    ddp_x_appr_deptshift_rec.attribute5 := p9_a27;
    ddp_x_appr_deptshift_rec.attribute6 := p9_a28;
    ddp_x_appr_deptshift_rec.attribute7 := p9_a29;
    ddp_x_appr_deptshift_rec.attribute8 := p9_a30;
    ddp_x_appr_deptshift_rec.attribute9 := p9_a31;
    ddp_x_appr_deptshift_rec.attribute10 := p9_a32;
    ddp_x_appr_deptshift_rec.attribute11 := p9_a33;
    ddp_x_appr_deptshift_rec.attribute12 := p9_a34;
    ddp_x_appr_deptshift_rec.attribute13 := p9_a35;
    ddp_x_appr_deptshift_rec.attribute14 := p9_a36;
    ddp_x_appr_deptshift_rec.attribute15 := p9_a37;
    ddp_x_appr_deptshift_rec.dml_operation := p9_a38;
    ddp_x_appr_deptshift_rec.dept_latitude := p9_a39;
    ddp_x_appr_deptshift_rec.dept_longitude := p9_a40;

    -- here's the delegated call to the old PL/SQL routine
    ahl_appr_dept_shifts_pub.edit_appr_dept_shifts(p_api_version,
      p_init_msg_list,
      p_commit,
      p_validation_level,
      p_default,
      p_module_type,
      x_return_status,
      x_msg_count,
      x_msg_data,
      ddp_x_appr_deptshift_rec);

    -- copy data back from the local variables to OUT or IN-OUT args, if any









    p9_a0 := ddp_x_appr_deptshift_rec.ahl_department_shifts_id;
    p9_a1 := ddp_x_appr_deptshift_rec.organization_id;
    p9_a2 := ddp_x_appr_deptshift_rec.organization_name;
    p9_a3 := ddp_x_appr_deptshift_rec.object_version_number;
    p9_a4 := ddp_x_appr_deptshift_rec.last_update_date;
    p9_a5 := ddp_x_appr_deptshift_rec.last_updated_by;
    p9_a6 := ddp_x_appr_deptshift_rec.creation_date;
    p9_a7 := ddp_x_appr_deptshift_rec.created_by;
    p9_a8 := ddp_x_appr_deptshift_rec.last_update_login;
    p9_a9 := ddp_x_appr_deptshift_rec.department_id;
    p9_a10 := ddp_x_appr_deptshift_rec.dept_description;
    p9_a11 := ddp_x_appr_deptshift_rec.calendar_code;
    p9_a12 := ddp_x_appr_deptshift_rec.calendar_description;
    p9_a13 := ddp_x_appr_deptshift_rec.bom_workday_patterns_id;
    p9_a14 := ddp_x_appr_deptshift_rec.shift_num;
    p9_a15 := ddp_x_appr_deptshift_rec.seq_num;
    p9_a16 := ddp_x_appr_deptshift_rec.seq_name;
    p9_a17 := ddp_x_appr_deptshift_rec.subinventory;
    p9_a18 := ddp_x_appr_deptshift_rec.inv_locator_id;
    p9_a19 := ddp_x_appr_deptshift_rec.locator_segments;
    p9_a20 := ddp_x_appr_deptshift_rec.max_service_category;
    p9_a21 := ddp_x_appr_deptshift_rec.description;
    p9_a22 := ddp_x_appr_deptshift_rec.attribute_category;
    p9_a23 := ddp_x_appr_deptshift_rec.attribute1;
    p9_a24 := ddp_x_appr_deptshift_rec.attribute2;
    p9_a25 := ddp_x_appr_deptshift_rec.attribute3;
    p9_a26 := ddp_x_appr_deptshift_rec.attribute4;
    p9_a27 := ddp_x_appr_deptshift_rec.attribute5;
    p9_a28 := ddp_x_appr_deptshift_rec.attribute6;
    p9_a29 := ddp_x_appr_deptshift_rec.attribute7;
    p9_a30 := ddp_x_appr_deptshift_rec.attribute8;
    p9_a31 := ddp_x_appr_deptshift_rec.attribute9;
    p9_a32 := ddp_x_appr_deptshift_rec.attribute10;
    p9_a33 := ddp_x_appr_deptshift_rec.attribute11;
    p9_a34 := ddp_x_appr_deptshift_rec.attribute12;
    p9_a35 := ddp_x_appr_deptshift_rec.attribute13;
    p9_a36 := ddp_x_appr_deptshift_rec.attribute14;
    p9_a37 := ddp_x_appr_deptshift_rec.attribute15;
    p9_a38 := ddp_x_appr_deptshift_rec.dml_operation;
    p9_a39 := ddp_x_appr_deptshift_rec.dept_latitude;
    p9_a40 := ddp_x_appr_deptshift_rec.dept_longitude;
  end;

end ahl_appr_dept_shifts_pub_w;
