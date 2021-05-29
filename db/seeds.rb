# coding: utf-8

User.create!(name: "管理者",
             email: "admin@email.com",
             password: "password",
             department: "本社",
             password_confirmation: "password",
             emp_id: "999",
             admin: true)

User.create!(name: "サンプル１",
             email: "sample1@email.com",
             department: "A店",
             password: "password",
             emp_id: "1001",
             position: "社員",
             password_confirmation: "password",)
             
User.create!(name: "サンプル２",
             email: "sample2@email.com",
             department: "A店",
             password: "password",
             emp_id: "1002",
             position: "社員",
             password_confirmation: "password")

User.create!(name: "サンプル３",
             email: "sample3@email.com",
             department: "B店",
             password: "password",
             emp_id: "1003",
             position: "社員",
             password_confirmation: "password")

User.create!(name: "サンプル４",
             email: "sample4@email.com",
             department: "C店",
             password: "password",
             emp_id: "1004",
             position: "社員",
             password_confirmation: "password")

User.create!(name: "サンプル５",
             email: "sample5@email.com",
             department: "C店",
             password: "password",
             emp_id: "9001",
             position: "パートナー",
             password_confirmation: "password")