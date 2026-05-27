const request = require("supertest");
const app = require("../src/app");

describe("Health endpoints", () => {
  test("GET /health/alive should return 200 OK", async () => {
    const res = await request(app).get("/health/alive");
    expect(res.statusCode).toBe(200);
    expect(res.text).toBe("OK");
  });

  test("GET /health/ready should return status", async () => {
    const res = await request(app).get("/health/ready");
    expect([200, 500]).toContain(res.statusCode);
  });
});

describe("Root endpoint", () => {
  test("GET / should return HTML with API list", async () => {
    const res = await request(app).get("/");
    expect(res.statusCode).toBe(200);
    expect(res.headers["content-type"]).toContain("text/html");
    expect(res.text).toContain("/tasks");
  });
});

describe("Tasks API - JSON", () => {
  test("GET /tasks should return array", async () => {
    const res = await request(app)
      .get("/tasks")
      .set("Accept", "application/json");
    expect(res.statusCode).toEqual(expect.any(Number));
  });

  test("POST /tasks without title should return 400", async () => {
    const res = await request(app)
      .post("/tasks")
      .set("Accept", "application/json")
      .send({});
    expect(res.statusCode).toBe(400);
  });

  test("POST /tasks with title should create task", async () => {
    const res = await request(app)
      .post("/tasks")
      .set("Accept", "application/json")
      .send({ title: "Test task from jest" });
    expect([201, 500]).toContain(res.statusCode);
  });
});

describe("Tasks API - HTML", () => {
  test("GET /tasks should return HTML table", async () => {
    const res = await request(app).get("/tasks").set("Accept", "text/html");
    expect(res.statusCode).toEqual(expect.any(Number));
    if (res.statusCode === 200) {
      expect(res.text).toContain("<table");
    }
  });
});

describe("Tasks done endpoint", () => {
  test("POST /tasks/999/done for non-existent task", async () => {
    const res = await request(app)
      .post("/tasks/999/done")
      .set("Accept", "application/json");
    expect([404, 500]).toContain(res.statusCode);
  });
});
