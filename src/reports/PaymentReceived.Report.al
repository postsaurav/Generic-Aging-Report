report 50000 "SDH Payment Received"
{
    Caption = 'Payment Received';
    UsageCategory = ReportsAndAnalysis;
    ApplicationArea = All;
    DefaultLayout = RDLC;
    RDLCLayout = './src/reports/PaymentReceived.rdl';

    dataset
    {
        dataitem(Customer; Customer)
        {
            column(CustomerNo; "No.")
            {
                IncludeCaption = true;
            }
            column(CustomerName; Name)
            {
                IncludeCaption = true;
            }
            dataitem(Integer; Integer)
            {
                DataItemTableView = SORTING(Number) Order(Ascending);
                column(col_Array; Number) { }
                column(StartDateCol; PeriodstartDate.Get(Number)) { }
                column(EndDateCol; PeriodendDate.Get(Number)) { }
                column(PaymentValue; -TotalAmount) { }

                trigger OnPreDataItem()
                begin
                    SetRange(Number, 1, NoofPeriods);
                end;

                trigger OnAfterGetRecord()
                var
                    CustLedgerEntry: Record "Cust. Ledger Entry";
                begin
                    Clear(TotalAmount);
                    CustLedgerEntry.Reset();
                    CustLedgerEntry.SetRange("Customer No.", Customer."No.");
                    CustLedgerEntry.SetRange("Document Type", CustLedgerEntry."Document Type"::Payment);
                    CustLedgerEntry.SetRange("Posting Date", PeriodStartDate.Get(Integer.Number), PeriodEndDate.Get(Integer.Number));
                    IF CustLedgerEntry.FindSet() then
                        repeat
                            CustLedgerEntry.CalcFields("Amount (LCY)");
                            TotalAmount := TotalAmount + CustLedgerEntry."Amount (LCY)";
                        until (CustLedgerEntry.Next() = 0);
                end;
            }
        }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                group(GroupName)
                {
                    field(StartDate; StartDate)
                    {
                        ApplicationArea = All;
                        Caption = 'Start Date';
                        ToolTip = 'Start Date';
                    }
                    field(NoofPeriods; NoofPeriods)
                    {
                        ApplicationArea = All;
                        Caption = 'No of Periods';
                        ToolTip = 'No of Periods';
                    }
                    field(MonthsPerPeriod; MonthsPerPeriod)
                    {
                        ApplicationArea = All;
                        Caption = 'Months Per Period';
                        ToolTip = 'Months Per Period';
                    }
                }
            }
        }
    }

    trigger OnPreReport()
    begin
        If (StartDate = 0D) OR (NoofPeriods = 0) OR (MonthsPerPeriod = 0) then
            Error('Please input Values');
        CalculateDateArrays();
    end;

    local procedure CalculateDateArrays()
    var
        LocalDateFormula: DateFormula;
        LoopCnt: Integer;
        LocalDate: Date;
        DateForumlaTxt: text;
    begin
        DateForumlaTxt := '<' + Format(MonthsPerPeriod) + 'M>';
        Evaluate(LocalDateFormula, DateForumlaTxt);

        PeriodstartDate.Add(StartDate);
        LocalDate := StartDate;

        repeat
            LocalDate := CalcDate(LocalDateFormula, LocalDate);
            PeriodEndDate.Add(CalcDate('<-1D>', LocalDate));
            PeriodstartDate.Add(LocalDate);
            LoopCnt += 1;
        until (LoopCnt >= NoofPeriods);
        PeriodEndDate.Add(CalcDate(LocalDateFormula, LocalDate));
    end;

    var
        StartDate: Date;
        TotalAmount: Decimal;
        NoofPeriods: Integer;
        MonthsPerPeriod: Integer;
        PeriodstartDate: List of [Date];
        PeriodEndDate: List of [Date];
}