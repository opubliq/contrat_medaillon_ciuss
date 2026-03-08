#let parse-date(date) = {
  if date == none or date == "" {
    return datetime.today()
  }
  let date = str(date).replace("\\", "")
  // Check if it contains brackets (placeholder text)
  if date.contains("[") {
    return datetime.today()
  }
  let date-parts = date.split("-")
  if date-parts.len() != 3 {
    return datetime.today()
  }
  let year = int(date-parts.at(0))
  let month = int(date-parts.at(1))
  let day = int(date-parts.at(2))
  datetime(year: year, month: month, day: day)
}

#let format-date(date) = {
  let day = date.day()
  let ord = super(if 10 < day and day < 20 {
    "th"
  } else if calc.rem(day, 10) == 1 {
    "st"
  } else if calc.rem(day, 10) == 2 {
    "nd"
  } else if calc.rem(day, 10) == 3 {
    "rd"
  } else {
    "th"
  })
  [the #day#ord of #date.display("[month repr:long]"), #date.year()]
}

#let count-days(x, y) = {
  let duration = y - x
  str(duration.days())
}

#let invoice(
  logo: none,
  title: none,
  description: none,
  sender: none,
  recipient: none,
  invoice: none,
  fee: 2.28,
  penalty: "€40",
  paper: "a4",
  margin: (x: 2.5cm, y: 2.5cm),
  lang: "en",
  region: "UK",
  font: "Alegreya Sans",
  heading-family: none,
  heading-weight: "bold",
  heading-style: "normal",
  heading-color: black,
  heading-line-height: 0.65em,
  fontsize: 12pt,
  title-size: 1.5em,
  body
) = {

  show heading: it => [
    #set par(leading: heading-line-height)
    #set text(font: heading-family, weight: heading-weight, style: heading-style, fill: heading-color)
    #it.body
  ]

  let issued = parse-date(invoice.at("issued"))
  if "penalty" in invoice and invoice != none {
    let penalty = invoice.at("penalty", default: "€40")
  } else {
    let penalty = "€40"
  }
  if "fee" in invoice and invoice != none {
    let fee = invoice.at("fee", default: 2.28)
  } else {
    let fee = 2.28
  }

  set document(
    title: "Invoice " + invoice.at("number").replace("\\", "") + " - " + recipient.at("name").replace("\\", ""),
    author: sender.at("name").replace("\\", ""),
    date: issued
  )
  set page(
    paper: paper,
    margin: margin,
  )
  set par(justify: true)
  set text(
    lang: lang,
    region: region,
    font: font,
    size: fontsize,
  )

  grid(
    columns: (50%, 50%),
    align(left, {
      heading(level: 2, sender.at("name").replace("\\", ""))

      if "address" in sender and sender != none {
        v(fontsize * 0.5)
        emph(sender.at("address").at("street").replace("\\", ""))
        linebreak()
        sender.at("address").at("zip").replace("\\", "") + " " + sender.at("address").at("city").replace("\\", "")
        if "state" in sender.at("address") and not sender.at("address").at("state") in (none, "") {
          ", " + sender.at("address").at("state").replace("\\", "")
        } else {
          ""
        }
        linebreak()
        sender.at("address").at("country").replace("\\", "")
      }

      v(fontsize * 0.1)

      if "email" in sender and sender != none {
        link("mailto:" + sender.at("email").replace("\\", ""))
      } else {
        hide("a")
      }
    }),
    align(right, {
      heading(level: 2, recipient.at("name").replace("\\", ""))

      if "address" in recipient and recipient != none {
        v(fontsize * 0.5)
        emph(recipient.at("address").at("street").replace("\\", ""))
        linebreak()
        recipient.at("address").at("zip").replace("\\", "") + " " + recipient.at("address").at("city").replace("\\", "")
        if "state" in recipient.at("address") and not recipient.at("address").at("state") in (none, "") {
          ", " + recipient.at("address").at("state").replace("\\", "")
        } else {
          ""
        }
        linebreak()
        recipient.at("address").at("country").replace("\\", "")
      }
    })
  )

  v(fontsize * 1)

  grid(
    columns: (50%, 50%),
    align(left, {
      if "registration" in sender and sender != none and sender.at("registration") != "" {
        "Numéro d'enregistrement : " + sender.at("registration").replace("\\", "")
        linebreak()
      } else {
        hide("a")
      }

      if "vat" in sender and sender != none and sender.at("vat") != "" {
        "Numéro de TVA : " + sender.at("vat").replace("\\", "")
      } else {
        hide("a")
      }

      v(fontsize * 1)

      if "number" in invoice and invoice != none and invoice.at("number") != "" {
        "Numéro de facture : " + invoice.at("number").replace("\\", "")
        linebreak()
      } else {
        hide("a")
      }

      if "issued" in invoice and invoice != none {
        "Émise le : " + invoice.at("issued").replace("\\", "")
        linebreak()
      } else {
        hide("a")
      }

      if "due" in invoice and invoice != none {
        "Date d'échéance : " + invoice.at("due").replace("\\", "")
      } else {
        hide("a")
      }
    }),
    align(center, {
      if logo != "none" and logo != none {
        image(logo, width: 3cm)
      } else {
        hide("a")
      }
    })
  )

  align(horizon, {
    if title != none {
      heading(level: 1, title.replace("\\", ""))
      if description != none {
        emph(description.replace("\\", ""))
      }
    }

    body

    align(right, if "exempted" in sender and sender != none and sender.exempted != "none" and sender.exempted != none {
      text(luma(100), emph(sender.at("exempted").replace("\\", "")))
    } else {
      hide("a")
    })
  })
}

#show: invoice.with(
$if(title)$
  title: "$title$",
  $if(description)$
    description: "$description$",
  $endif$
$endif$
$if(logo)$
  logo: "$logo$",
$elseif(brand.logo)$
  font: ("$brand.logo$",),
$endif$
  sender: (
    name: "$if(sender.name)$$sender.name$$else$Hubert CADIEUX$endif$",
    address: (
      street: "$if(sender.address.street)$$sender.address.street$$else$304-7430 rue Lajeunesse$endif$",
      zip: "$if(sender.address.zip)$$sender.address.zip$$else$H2R 2H8$endif$",
      city: "$if(sender.address.city)$$sender.address.city$$else$Montréal$endif$",
      state: "$if(sender.address.state)$$sender.address.state$$else$$endif$",
      country: "$if(sender.address.country)$$sender.address.country$$else$Canada$endif$"
    ),
    email: "$if(sender.email)$$sender.email$$else$hubert.cadieux.1@ulaval.ca$endif$",
    registration: "$if(sender.registration)$$sender.registration$$else$$endif$",
    vat: "$if(sender.vat)$$sender.vat$$else$$endif$",
    exempted: "$if(sender.exempted)$$sender.exempted$$else$Exempted from GST/HST in Canada due to self-employment under the income threshold$endif$"
  ),
$if(recipient)$
  recipient: (
    name: "$recipient.name$",
    address: (
      street: "$recipient.address.street$",
      zip: "$recipient.address.zip$",
      city: "$recipient.address.city$",
      state: "$recipient.address.state$",
      country: "$recipient.address.country$"
    )
  ),
$endif$
$if(invoice)$
  invoice: (
    number: "$invoice.number$",
    issued: "$invoice.issued$",
    due: "$invoice.due$",
    reference: "$invoice.reference$",
    fee: "$invoice.fee$",
    penalty: "$invoice.penalty$"
  ),
$endif$
$if(bank)$
  bank: (
    iban: "$bank.iban$",
    bic: "$bank.bic$"
  ),
$endif$
$if(lang)$
  lang: "$lang$",
$endif$
$if(region)$
  region: "$region$",
$endif$
$if(margin)$
  margin: ($for(margin/pairs)$$margin.key$: $margin.value$,$endfor$),
$endif$
$if(papersize)$
  paper: "$papersize$",
$endif$
$if(mainfont)$
  font: "$mainfont$",
$elseif(brand.typography.base.family)$
  font: "$brand.typography.base.family$",
$endif$
$if(fontsize)$
  fontsize: $fontsize$,
$elseif(brand.typography.base.size)$
  fontsize: $brand.typography.base.size$,
$endif$
$if(title)$
$if(brand.typography.headings.family)$
  heading-family: $brand.typography.headings.family$,
$endif$
$if(brand.typography.headings.weight)$
  heading-weight: $brand.typography.headings.weight$,
$endif$
$if(brand.typography.headings.style)$
  heading-style: "$brand.typography.headings.style$",
$endif$
$if(brand.typography.headings.color)$
  heading-color: $brand.typography.headings.color$,
$endif$
$if(brand.typography.headings.line-height)$
  heading-line-height: $brand.typography.headings.line-height$,
$endif$
$endif$
)

$body$
