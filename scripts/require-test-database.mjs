const value=process.env.TEST_DATABASE_URL;
if(!value){console.error("BLOCKED: TEST_DATABASE_URL is required and must target disposable local or dedicated test PostgreSQL.");process.exit(2);}
const url=new URL(value);const database=url.pathname.slice(1).toLowerCase();
if(!["127.0.0.1","localhost"].includes(url.hostname)&&!database.includes("test")){console.error("REFUSED: database target is neither local nor explicitly named as a test database.");process.exit(2);}
