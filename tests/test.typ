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

// Salary-dependent bounds (0.1.1), as eorscope.com prints them.
// ES: "at least" above the maximum base (EUR 61,214.40), a total at and below it.
#assert.eq(country("ES").total_bound_salary_threshold_local, 61214.4)
#assert.eq(country("ES").total_bound_salary_rule, "at_least_above")
#assert(employer-rate-text("ES", salary: 70000).starts-with("at least "))
#assert(employer-cost("ES", 70000).rate-is-floor)
#assert(not employer-rate-text("ES", salary: 40000).starts-with("at "))
#assert(not employer-cost("ES", 40000).rate-is-floor)
#assert(not employer-rate-text("ES", salary: 61214.4).starts-with("at "))
#assert.eq(employer-rate-text("ES"), "32.2%")
// FR: "at most" under 3 x SMIC (EUR 65,629), a total at and above it.
#assert.eq(country("FR").total_bound_salary_threshold_local, 65629.0)
#assert.eq(country("FR").total_bound_salary_rule, "at_most_below")
#assert(employer-rate-text("FR", salary: 44755).starts-with("at most "))
#assert(employer-cost("FR", 44755).rate-is-ceiling)
#assert(not employer-cost("FR", 44755).rate-is-floor)
#assert(not employer-rate-text("FR", salary: 80000).starts-with("at "))
#assert(not employer-cost("FR", 80000).rate-is-ceiling)
#assert(not employer-rate-text("FR", salary: 65629).starts-with("at "))
#assert.eq(employer-rate-text("FR"), "48.2%")
// No other country carries a salary-dependent bound; declared floors are unchanged.
#assert.eq(countries().filter(c => c.total_bound_salary_rule != none).map(c => c.iso), ("ES", "FR"))
#assert(employer-cost("IN", 1).rate-is-floor)
#assert(not employer-cost("DE", 60000).rate-is-ceiling)

// Tables render.
#employer-cost-table("ES", 70000)
#employer-cost-table("FR", 44755)
#employer-cost-table("DE", 60000)
#employer-cost-table("IN", 1200000)
#employer-rates-table(region: "Europe")

// Figures quoted in the README.
#let de60 = employer-cost("DE", 60000)
#assert(calc.abs(de60.cost - 13350) < 1e-9)
#assert(calc.abs(de60.total - 73350) < 1e-9)
#assert(calc.abs(de60.rate - 0.2225) < 1e-12)
