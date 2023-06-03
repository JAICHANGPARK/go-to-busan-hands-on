package main

import (
	"database/sql"
	"fmt"
	"log"
	"strconv"

	"github.com/gofiber/fiber/v2"
	_ "github.com/mattn/go-sqlite3"
	"github.com/projectdiscovery/gologger"
)

type ResponseModel struct {
	Code    int     `json:"code"`
	Message string  `json:"message"`
	Diary   []Diary `json:"items"`
}

// Field names should start with an uppercase letter
type Diary struct {
	Id        string `json:"id" xml:"id" form:"id"`
	Uuid      string `json:"uuid"`
	Note      string `json:"note" xml:"note" form:"note"`
	Dt        string `json:"dt"`
	Timestamp int    `json:"timestamp"`
}

var (
	myDB *sql.DB
)

func checkErr(err error) {
	if err != nil {
		gologger.Error().Msgf(err.Error())
	}
}

func createTestTable() {
	query := `
		CREATE TABLE IF NOT EXISTS diary (
			id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
			uuid TEXT,
			note TEXT,
			dt TEXT,
			timestamp INTEGER
		);
	`
	if _, err := myDB.Exec(query); err != nil {
		checkErr(err)
	}
}

func insertDiaryItem(uuid string, note string, dt string, timestamp int) {
	query := `INSERT INTO diary VALUES(NULL,?,?,?,?)`
	if _, err := myDB.Exec(query, uuid, note, dt, timestamp); err != nil {
		checkErr(err)
	}
	gologger.Info().Msgf("데이터 삽입 완료!")
}

func deleteDiartItem(uuid string) {
	query := `DELETE FROM diary WHERE uuid=?;`
	if _, err := myDB.Exec(query, uuid); err != nil {
		checkErr(err)
	}
}

func main() {
	db, err := sql.Open("sqlite3", "mydb.db")
	checkErr(err)
	defer db.Close()
	myDB = db
	createTestTable()
	// insertTestData("hello", "29", "서울시")

	app := fiber.New()

	app.Post("/diary", func(c *fiber.Ctx) error {
		item := new(Diary)

		if err := c.BodyParser(item); err != nil {
			return err
		}
		insertDiaryItem(item.Uuid, item.Note, item.Dt, item.Timestamp)
		return c.JSON(item)
	})

	app.Get("/diary", func(c *fiber.Ctx) error {

		search := c.Query("search")
		log.Println(search)
		rows, err := myDB.Query("SELECT * FROM diary WHERE Date(dt) = Date(?)", search)

		if err != nil {
			log.Panicln(err)
		}

		tmps := make([]Diary, 0)

		for rows.Next() {
			var result Diary
			rows.Scan(&result.Id, &result.Uuid, &result.Note, &result.Dt, &result.Timestamp)
			gologger.Info().Msgf("UUID : " + result.Uuid)
			gologger.Info().Msgf("노트내용 : " + result.Note)
			gologger.Info().Msgf("Datetime : " + result.Dt)
			gologger.Info().Msgf("Timestamp : " + fmt.Sprintf("%v", result.Timestamp))
			fmt.Println("===================================================================")
			tmps = append(tmps, result)
		}
		return c.JSON(ResponseModel{200, strconv.Itoa(len(tmps)), tmps})

	})

	app.Delete("/diary", func(c *fiber.Ctx) error {
		uuid := c.Query("uuid")
		log.Println(uuid)
		deleteDiartItem(uuid)
		return c.JSON("200")
	})

	app.Get("/", func(c *fiber.Ctx) error {
		return c.SendString("Hello, World 👋!")
	})

	app.Listen(":3000")
}
