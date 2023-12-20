

-- EXEC GetInvoicePaymentsHistory 30, 13
CREATE PROCEDURE [dbo].[GetInvoicePaymentsHistory]
@InvoicingId bigint,
@ReceiptId bigint
AS
BEGIN
SELECT iv.PaymentAuditId,
	   iv.ReceiptId,
       cp.ReceiptNo,
       iv.DocNum,
	   iv.WOSONum,
	   iv.InvoiceDate,
	   iv.OriginalAmount,
	   iv.RemainingAmount,
	   iv.NewRemainingBal,
       iv.PaymentAmount,
	   iv.DiscAmount,
	   dt.[Name] 'DiscType',
	   iv.BankFeeAmount,
       bf.[Name] 'BankFeeType',
       iv.OtherAdjustAmt,
       ar.[Name] 'Reason',
	   iv.IsDeleted,
	   iv.CreatedBy,
	   iv.CreatedDate,
	   iv.UpdatedBy,
	   iv.UpdatedDate
  FROM dbo.InvoicePaymentsAudit iv 
  INNER JOIN CustomerPayments cp on iv.ReceiptId=cp.ReceiptId
  LEFT JOIN dbo.MasterDiscountType dt on iv.DiscType=dt.Id
  LEFT JOIN dbo.MasterBankFeesType bf on iv.BankFeeType=bf.Id
  LEFT JOIN dbo.MasterAdjustReason ar on iv.Reason=ar.Id
  WHERE iv.SOBillingInvoicingId = @InvoicingId 
  ORDER BY iv.PaymentAuditId DESC
  --AND iv.ReceiptId = @ReceiptId;
END