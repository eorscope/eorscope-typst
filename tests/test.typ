// Compile with: typst compile --root . tests/test.typ
// Every assertion failure stops the compilation with a non-zero exit code.
#import "../lib.typ": *

// Every country: the engine, run at the example salary, gives back the figures
// published in country_summary.csv (4-decimal percent, printed percent, USD/month).
#let bad = ()
#for c in countries() {
  let r = _compute(c, c.example_salary_usd * c.fx_local_per_usd, c.example_salary_usd)
  let got = (
    float(format-percent(r.rate, digits: 4)),
    float(format-percent(r.rate, digits: 1)),
    float(_fixed(calc.round(r.cost-usd / 12.0 * 1e6) / 1e6, 2)),
  )
  let want = (c.employer_cost_pct, float(c.employer_cost_pct_printed), c.employer_cost_usd_month)
  if got != want { bad.push(c.iso + ": got " + repr(got) + ", want " + repr(want)) }
}
#assert(bad.len() == 0, message: str(bad.len()) + " mismatches: " + bad.join("; "))
#assert.eq(countries().len(), 76)
#assert.eq(countries().map(c => c.lines.len()).sum(), 544)

// Named vectors, copied from country_summary.csv (export 2026-10-13).
#assert.eq(employer-rate("DE"), 0.2225)
#assert.eq(employer-rate-text("de"), "22.3%")
#assert.eq(employer-rate-text("ES"), "32.2%")
#assert.eq(employer-rate-text("IN"), "at least 3.8%")
#assert.eq(employer-rate-text("AM"), "0%")
#assert.eq(employer-rate-text("AT"), "30%")
#assert.eq(employer-rate-text("PK"), "1%")
#assert(rate-is-floor("IN"))
#assert(not rate-is-floor("DE"))

// A local salary equal to the example salary gives the published rate.
#let de = country("DE")
#let r = employer-cost("DE", de.example_salary_usd * de.fx_local_per_usd)
#assert.eq(format-percent(r.rate, digits: 4), "22.2500")
#assert(calc.abs(r.cost / r.salary - r.rate) < 1e-12)
#assert.eq(r.total, r.salary + r.cost)
#assert.eq(employer-rate("DE", salary: de.example_salary_usd * de.fx_local_per_usd), r.rate)

// Rounding as eorscope.com prints it.
#assert.eq(_fixed(22.25, 1), "22.3")
#assert.eq(_fixed(1390.625, 2), "1390.63")
#assert.eq(_fixed(0.0, 2), "0.00")
#assert.eq(_fixed(32.15, 1), "32.2")
#assert.eq(_fixed(9.995, 2), "10.00")
#assert.eq(_fixed(99.95, 1), "100.0")
#assert.eq(_fixed(0.0000001, 2), "0.00")
#assert.eq(format-amount(1234567.891), "1,234,567.89")
#assert.eq(format-amount(123, digits: 0), "123")

// Tables render.
#employer-cost-table("DE", 60000)
#employer-cost-table("IN", 1200000)
#employer-rates-table(region: "Europe")

// Figures quoted in the README.
#let de60 = employer-cost("DE", 60000)
#assert(calc.abs(de60.cost - 13350) < 1e-9)
#assert(calc.abs(de60.total - 73350) < 1e-9)
#assert(calc.abs(de60.rate - 0.2225) < 1e-12)
