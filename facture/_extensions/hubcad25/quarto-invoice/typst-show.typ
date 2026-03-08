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
  font: ("$mainfont$",),
$elseif(brand.typography.base.family)$
  font: ("$brand.typography.base.family$",),
$endif$
$if(fontsize)$
  fontsize: $fontsize$,
$elseif(brand.typography.base.size)$
  fontsize: $brand.typography.base.size$,
$endif$
$if(title)$
$if(brand.typography.headings.family)$
  heading-family: ("$brand.typography.headings.family$",),
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
