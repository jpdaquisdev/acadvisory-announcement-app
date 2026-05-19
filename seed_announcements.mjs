import { initializeApp } from "firebase/app";
import {
  getFirestore,
  doc,
  writeBatch,
  Timestamp,
} from "firebase/firestore";

const firebaseConfig = {
  apiKey: "AIzaSyDOZMbeXhlt0A6QTXWrBNgWMTRAv2Kbt1M",
  authDomain: "announcement-test-d8873.firebaseapp.com",
  projectId: "announcement-test-d8873",
  storageBucket: "announcement-test-d8873.firebasestorage.app",
  messagingSenderId: "101630113383",
  appId: "1:101630113383:web:f3da09a897bcd42b5106c2",
  measurementId: "G-GKQBJDESHT",
};

const app = initializeApp(firebaseConfig);
const db = getFirestore(app);

const announcements = [
  {
    id: "seed_announcement_001",
    title: "Application to Graduation",
    category: "Academics",
    details:
      "Students who are applying for graduation must submit all required forms and clearance documents before the deadline. Please check your department office for final requirements.",
    createdAt: Timestamp.fromDate(new Date(2026, 4, 14, 9, 35)),
  },
  {
    id: "seed_announcement_002",
    title: "New Sets of FCMS Officers",
    category: "Organization",
    details:
      "The new set of FCMS officers has been officially announced. Students may view the list of officers and their assigned roles through the organization bulletin.",
    createdAt: Timestamp.fromDate(new Date(2026, 4, 14, 9, 35)),
  },
  {
    id: "seed_announcement_003",
    title: "Shift to Online Classes",
    category: "Urgent",
    details:
      "Due to weather conditions, all classes will temporarily shift to online learning. Students are advised to check their learning platforms for class links and instructions.",
    createdAt: Timestamp.fromDate(new Date(2026, 4, 14, 10, 15)),
  },
  {
    id: "seed_announcement_004",
    title: "Finals Exam Schedule",
    category: "Academics",
    details:
      "Attention, Technocrats! Please be informed of the official schedule for the final examinations. Kindly review the details carefully and prepare all requirements before your exam day.",
    createdAt: Timestamp.fromDate(new Date(2026, 4, 20, 8, 0)),
  },
  {
    id: "seed_announcement_005",
    title: "Campus Clean-Up Drive",
    category: "Campus Updates",
    details:
      "All students are invited to join the campus clean-up drive this Friday. Participants are encouraged to bring cleaning materials and wear comfortable clothing.",
    createdAt: Timestamp.fromDate(new Date(2026, 4, 20, 13, 30)),
  },
  {
    id: "seed_announcement_006",
    title: "Intramurals Opening Program",
    category: "Events",
    details:
      "The school intramurals opening program will be held at the covered court. All departments are encouraged to attend and support their teams.",
    createdAt: Timestamp.fromDate(new Date(2026, 4, 21, 8, 30)),
  },
  {
    id: "seed_announcement_007",
    title: "Library Schedule Update",
    category: "Campus Updates",
    details:
      "The library will extend its operating hours during examination week. Students may use the library for review sessions and academic research.",
    createdAt: Timestamp.fromDate(new Date(2026, 4, 21, 11, 0)),
  },
  {
    id: "seed_announcement_008",
    title: "Scholarship Application Reminder",
    category: "Academics",
    details:
      "Students interested in scholarship programs must submit their application forms, grades, and supporting documents to the scholarship office.",
    createdAt: Timestamp.fromDate(new Date(2026, 4, 22, 9, 0)),
  },
  {
    id: "seed_announcement_009",
    title: "Emergency Fire Drill",
    category: "Urgent",
    details:
      "A campus-wide fire drill will be conducted. Students, faculty, and staff must follow safety protocols and proceed to designated evacuation areas.",
    createdAt: Timestamp.fromDate(new Date(2026, 4, 22, 14, 0)),
  },
  {
    id: "seed_announcement_010",
    title: "Student Council Meeting",
    category: "Organization",
    details:
      "All student council representatives are required to attend the meeting regarding upcoming student activities and organization plans.",
    createdAt: Timestamp.fromDate(new Date(2026, 4, 23, 10, 0)),
  },
  {
    id: "seed_announcement_011",
    title: "Sports Tryouts Announcement",
    category: "Events",
    details:
      "Tryouts for basketball, volleyball, and badminton teams will be held this week. Interested students must register with the sports coordinator.",
    createdAt: Timestamp.fromDate(new Date(2026, 4, 23, 15, 30)),
  },
  {
    id: "seed_announcement_012",
    title: "Faculty Evaluation Period",
    category: "Academics",
    details:
      "The faculty evaluation period is now open. Students are encouraged to answer the evaluation forms honestly and responsibly.",
    createdAt: Timestamp.fromDate(new Date(2026, 4, 24, 8, 45)),
  },
  {
    id: "seed_announcement_013",
    title: "Power Interruption Notice",
    category: "Urgent",
    details:
      "Please be advised that there will be a scheduled power interruption in selected campus areas due to maintenance work.",
    createdAt: Timestamp.fromDate(new Date(2026, 4, 24, 13, 0)),
  },
  {
    id: "seed_announcement_014",
    title: "Club Membership Registration",
    category: "Organization",
    details:
      "Registration for different school clubs is now open. Students may visit the organization booth to sign up and learn more.",
    createdAt: Timestamp.fromDate(new Date(2026, 4, 25, 9, 20)),
  },
  {
    id: "seed_announcement_015",
    title: "Campus Wi-Fi Maintenance",
    category: "Campus Updates",
    details:
      "The campus Wi-Fi service may be temporarily unavailable due to system maintenance. Internet access will resume after the update.",
    createdAt: Timestamp.fromDate(new Date(2026, 4, 25, 11, 45)),
  },
  {
    id: "seed_announcement_016",
    title: "Research Presentation Day",
    category: "Events",
    details:
      "Selected students will present their research projects in front of faculty panels. Participants must prepare their presentation materials in advance.",
    createdAt: Timestamp.fromDate(new Date(2026, 4, 26, 10, 30)),
  },
  {
    id: "seed_announcement_017",
    title: "Enrollment Advisory",
    category: "Academics",
    details:
      "Students are advised to check the enrollment schedule and complete their requirements before proceeding with registration.",
    createdAt: Timestamp.fromDate(new Date(2026, 4, 26, 14, 15)),
  },
  {
    id: "seed_announcement_018",
    title: "Lost and Found Reminder",
    category: "Campus Updates",
    details:
      "Students who lost personal belongings may visit the student affairs office. Found items must also be surrendered to the office.",
    createdAt: Timestamp.fromDate(new Date(2026, 4, 27, 9, 10)),
  },
  {
    id: "seed_announcement_019",
    title: "Academic Consultation Week",
    category: "Academics",
    details:
      "Students may schedule consultations with their instructors for academic concerns, project clarifications, and grade-related questions.",
    createdAt: Timestamp.fromDate(new Date(2026, 4, 27, 13, 40)),
  },
  {
    id: "seed_announcement_020",
    title: "Recognition Day Program",
    category: "Events",
    details:
      "The recognition day program will honor students with outstanding academic and extracurricular achievements. Awardees must arrive early.",
    createdAt: Timestamp.fromDate(new Date(2026, 4, 28, 8, 0)),
  },
];

async function seedAnnouncements() {
  const batch = writeBatch(db);

  announcements.forEach((announcement) => {
    const announcementRef = doc(db, "announcements", announcement.id);

    batch.set(announcementRef, {
      title: announcement.title,
      details: announcement.details,
      category: announcement.category,
      createdAt: announcement.createdAt,
    });
  });

  await batch.commit();

  console.log("Successfully inserted 20 announcements!");
}

seedAnnouncements().catch((error) => {
  console.error("Error inserting announcements:");
  console.error(error);
});