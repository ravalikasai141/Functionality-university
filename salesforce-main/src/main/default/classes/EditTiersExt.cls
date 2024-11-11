public class EditTiersExt {
    public Opportunity opp;
    private ApexPages.StandardController sc;
    
    public EditTiersExt(ApexPages.StandardController sc) {
        opp = (Opportunity)sc.getRecord();
        this.sc = sc;
    }
    
    public PageReference save() {
        PageReference detailPage = sc.save();
        opp.Tier_1__c = (tier1Options == '--None--' ? NULL : tier1Options);
        opp.Tier_2__c = (tier2Options == '--None--' ? NULL : tier2Options);
        opp.Tier_3__c = (tier3Options == '--None--' ? NULL : tier3Options);
        opp.Tier_4__c = (tier4Options == '--None--' ? NULL : tier4Options);
        opp.Tier_5__c = (tier5Options == '--None--' ? NULL : tier5Options);
        opp.Tier_6__c = (tier6Options == '--None--' ? NULL : tier6Options);
        update opp;
        
        if (detailPage != null) {
            return detailPage;
        } else {
            PageReference editPage = new PageReference(detailPage.getUrl() + '/e');
            return editPage;
        }
    }
    
    public String tier1Options {get; set;}
    public String tier2Options {get; set;}
    public String tier3Options {get; set;}
    public String tier4Options {get; set;}
    public String tier5Options {get; set;}
    public String tier6Options {get; set;}
    public List<SelectOption> createTier2Options = new List<SelectOption>{new SelectOption('--None--','--None--')};
    public List<SelectOption> createTier3Options = new List<SelectOption>{new SelectOption('--None--','--None--')};
    public List<SelectOption> createTier4Options = new List<SelectOption>{new SelectOption('--None--','--None--')};
    public List<SelectOption> createTier5Options = new List<SelectOption>{new SelectOption('--None--','--None--')};
    public List<SelectOption> createTier6Options = new List<SelectOption>{new SelectOption('--None--','--None--')};
    
    public void updateTier2Dropdown() {
        tier2Options = '';
        tier3Options = '';
        tier4Options = '';
        createTier2Options.clear();
        createTier3Options.clear();
        createTier4Options.clear();
        createTier3Options = new List<SelectOption>();
        createTier4Options = new List<SelectOption>();
        createTier5Options = new List<SelectOption>();
        createTier6Options = new List<SelectOption>();
        createTier3Options.add(new SelectOption('--None--','--None--'));
        createTier4Options.add(new SelectOption('--None--','--None--'));
        createTier5Options.add(new SelectOption('--None--','--None--'));
        createTier6Options.add(new SelectOption('--None--','--None--'));
        
        if (tier1Options == 'Accountancy and Tax') {
            createTier2Options = new List<SelectOption>();
            createTier2Options.add(new SelectOption('--None--','--None--'));
            createTier2Options.add(new SelectOption('Apprenticeship','Apprenticeship'));
            createTier2Options.add(new SelectOption('Bespoke','Bespoke'));
            createTier2Options.add(new SelectOption('Public Non-Apps','Public Non-Apps'));
        } else if (tier1Options == 'Actuarial Education') {
            createTier2Options = new List<SelectOption>();
            createTier2Options.add(new SelectOption('--None--','--None--'));
            createTier2Options.add(new SelectOption('Apprenticeship','Apprenticeship'));
            createTier2Options.add(new SelectOption('Public Non-Apps','Public Non-Apps'));
        } else if (tier1Options == 'Banking / Insurance / FS') {
            createTier2Options = new List<SelectOption>();
            createTier2Options.add(new SelectOption('--None--','--None--'));
            createTier2Options.add(new SelectOption('Apprenticeship','Apprenticeship'));
            createTier2Options.add(new SelectOption('Bespoke','Bespoke'));
            createTier2Options.add(new SelectOption('Public Non-Apps','Public Non-Apps'));
        } else if (tier1Options == 'DTS / MSC in Data Analytics') {
            createTier2Options = new List<SelectOption>();
            createTier2Options.add(new SelectOption('--None--','--None--'));
            createTier2Options.add(new SelectOption('Apprenticeship','Apprenticeship'));
            createTier2Options.add(new SelectOption('Public Non-Apps','Public Non-Apps'));
        } else if (tier1Options == 'GDA / wrap') {
            createTier2Options = new List<SelectOption>();
            createTier2Options.add(new SelectOption('--None--','--None--'));
            createTier2Options.add(new SelectOption('Bespoke','Bespoke'));
        } else if (tier1Options == 'Health') {
            createTier2Options = new List<SelectOption>();
            createTier2Options.add(new SelectOption('--None--','--None--'));
            createTier2Options.add(new SelectOption('Apprenticeship','Apprenticeship'));
            createTier2Options.add(new SelectOption('Bespoke','Bespoke'));
            createTier2Options.add(new SelectOption('Public Non-Apps','Public Non-Apps'));
        } else if (tier1Options == 'HR / Management / Business Admin') {
            createTier2Options = new List<SelectOption>();
            createTier2Options.add(new SelectOption('--None--','--None--'));
            createTier2Options.add(new SelectOption('Apprenticeship','Apprenticeship'));
            createTier2Options.add(new SelectOption('Bespoke','Bespoke'));
            createTier2Options.add(new SelectOption('Public Non-Apps','Public Non-Apps'));
        } else if (tier1Options == 'International') {
            createTier2Options = new List<SelectOption>();
            createTier2Options.add(new SelectOption('--None--','--None--'));
            createTier2Options.add(new SelectOption('Bespoke','Bespoke'));
            createTier2Options.add(new SelectOption('Public Non-Apps','Public Non-Apps'));
        } else if (tier1Options == 'Law') {
            createTier2Options = new List<SelectOption>();
            createTier2Options.add(new SelectOption('--None--','--None--'));
            createTier2Options.add(new SelectOption('Apprenticeship','Apprenticeship'));
            createTier2Options.add(new SelectOption('Public Non-Apps','Public Non-Apps'));
        } else if (Tier1Options == 'Other') {
            createTier2Options = new List<SelectOption>();
            createTier2Options.add(new SelectOption('--None--','--None--'));
            createTier2Options.add(new SelectOption('Apprenticeship','Apprenticeship'));
            createTier2Options.add(new SelectOption('Bespoke','Bespoke'));
            createTier2Options.add(new SelectOption('Public Non-Apps','Public Non-Apps'));
            createTier2Options.add(new SelectOption('Other','Other'));
        } else if (tier1Options == 'Other Technology Products') {
            createTier2Options = new List<SelectOption>();
            createTier2Options.add(new SelectOption('--None--','--None--'));
            createTier2Options.add(new SelectOption('Accelerated Training','Accelerated Training'));
            createTier2Options.add(new SelectOption('Apprenticeship','Apprenticeship'));
            createTier2Options.add(new SelectOption('Bespoke','Bespoke'));
            createTier2Options.add(new SelectOption('Key Skills Series','Key Skills Series'));
            createTier2Options.add(new SelectOption('Skills Bootcamps','Skills Bootcamps'));
        } else if (tier1Options == 'Professional Development') {
            createTier2Options = new List<SelectOption>();
            createTier2Options.add(new SelectOption('--None--','--None--'));
            createTier2Options.add(new SelectOption('Bespoke','Bespoke'));
            createTier2Options.add(new SelectOption('Public Non-Apps','Public Non-Apps'));
            createTier2Options.add(new SelectOption('Key Skills Series','Key Skills Series'));
        } else if (tier1Options == 'Risk / Compliance / Financial Crime') {
            createTier2Options = new List<SelectOption>();
            createTier2Options.add(new SelectOption('--None--','--None--'));
            createTier2Options.add(new SelectOption('Apprenticeship','Apprenticeship'));
            createTier2Options.add(new SelectOption('Bespoke','Bespoke'));
        } else if (tier1Options == 'UG / PG') {
            createTier2Options = new List<SelectOption>();
            createTier2Options.add(new SelectOption('--None--','--None--'));
            createTier2Options.add(new SelectOption('Bespoke','Bespoke'));
            createTier2Options.add(new SelectOption('Public Non-Apps','Public Non-Apps'));
        }
    }
    
    public void updateTier3Dropdown() {
        tier3Options = '';
        tier4Options = '';
        tier5Options = '';
        tier6Options = '';
        createTier3Options.clear();
        createTier4Options.clear();
        createTier5Options.clear();
        createTier6Options.clear();
        createTier4Options.add(new SelectOption('--None--','--None--'));
        createTier5Options.add(new SelectOption('--None--','--None--'));
        createTier6Options.add(new SelectOption('--None--','--None--'));
        
        if (tier1Options == 'Accountancy and Tax') {
            if (tier2Options == 'Apprenticeship') {
                createTier3Options = new List<SelectOption>();
                createTier3Options.add(new SelectOption('--None--','--None--'));
                createTier3Options.add(new SelectOption('PQ','PQ'));
                createTier3Options.add(new SelectOption('Apprenticeship School (Level 2/3/4/5)', 'Apprenticeship School (Level 2/3/4/5)'));
            } else if (tier2Options == 'Bespoke') {
                createTier3Options = new List<SelectOption>();
                createTier3Options.add(new SelectOption('--None--','--None--'));
            } else if (tier2Options == 'Public Non-Apps') {
                createTier3Options = new List<SelectOption>();
                createTier3Options.add(new SelectOption('--None--','--None--'));
                createTier3Options.add(new SelectOption('Malaysia BPP','Malaysia BPP'));
                createTier3Options.add(new SelectOption('PQ','PQ'));
            }
        } else if (tier1Options == 'Actuarial Education') {
            if (tier2Options == 'Apprenticeship') {
                createTier3Options = new List<SelectOption>();
                createTier3Options.add(new SelectOption('--None--','--None--'));
                createTier3Options.add(new SelectOption('ActEd','ActEd'));
            } else if (tier2Options == 'Public Non-Apps') {
                createTier3Options.add(new SelectOption('--None--','--None--'));
                createTier3Options.add(new SelectOption('ActEd','ActEd'));
                createTier3Options.add(new SelectOption('Malaysia BPP','Malaysia BPP'));
            }
        } else if (tier1Options == 'Banking / Insurance / FS') {
            if (tier2Options == 'Apprenticeship') {
                createTier3Options = new List<SelectOption>();
                createTier3Options.add(new SelectOption('--None--','--None--'));
                createTier3Options.add(new SelectOption('Apprenticeship School (Level 2/3/4/5)', 'Apprenticeship School (Level 2/3/4/5)'));
                createTier3Options.add(new SelectOption('School of FS (Level 2/3/4/5)', 'School of FS (Level 2/3/4/5)'));
                createTier3Options.add(new SelectOption('School of FS (Level 6/7)', 'School of FS (Level 6/7)'));
            } else if (tier2Options == 'Bespoke') {
                createTier3Options = new List<SelectOption>();
                createTier3Options.add(new SelectOption('--None--','--None--'));
            } else if (tier2Options == 'Public Non-Apps') {
                createTier3Options = new List<SelectOption>();
                createTier3Options.add(new SelectOption('--None--','--None--'));
                createTier3Options.add(new SelectOption('Malaysia BPP','Malaysia BPP'));
                createTier3Options.add(new SelectOption('PQ', 'PQ'));
                createTier3Options.add(new SelectOption('PQ (FS)','PQ (FS)'));
            }
        } else if (tier1Options == 'DTS / MSC in Data Analytics') {
            if (tier2Options == 'Apprenticeship') {
                createTier3Options = new List<SelectOption>();
                createTier3Options.add(new SelectOption('--None--','--None--'));
                createTier3Options.add(new SelectOption('School of Technology (Level 6/7)','School of Technology (Level 6/7)'));
            } else if (tier2Options == 'Public Non-Apps') {
                createTier3Options = new List<SelectOption>();
                createTier3Options.add(new SelectOption('--None--','--None--'));
                createTier3Options.add(new SelectOption('Malaysia BPP','Malaysia BPP'));
                createTier3Options.add(new SelectOption('School of Technology','School of Technology'));
            }
        } else if (tier1Options == 'GDA / wrap') {
            if (tier2Options == 'Bespoke') {
                createTier3Options = new List<SelectOption>();
                createTier3Options.add(new SelectOption('--None--','--None--'));
                createTier3Options.add(new SelectOption('School of Business','School of Business'));
            }
        } else if (tier1Options == 'Health') {
            if (tier2Options == 'Apprenticeship') {
                createTier3Options = new List<SelectOption>();
                createTier3Options.add(new SelectOption('--None--','--None--'));
                createTier3Options.add(new SelectOption('School of Nursing','School of Nursing'));
            } else if (tier2Options == 'Bespoke') {
                createTier3Options = new List<SelectOption>();
                createTier3Options.add(new SelectOption('--None--','--None--'));
            } else if (tier2Options == 'Public Non-Apps') {
                createTier3Options = new List<SelectOption>();
                createTier3Options.add(new SelectOption('--None--','--None--'));
                createTier3Options.add(new SelectOption('Malaysia BPP','Malaysia BPP'));
                createTier3Options.add(new SelectOption('School of Health','School of Health'));
                createTier3Options.add(new SelectOption('School of Nursing','School of Nursing'));
            }
        } else if (tier1Options == 'HR / Management / Business Admin') {
            if (tier2Options == 'Apprenticeship') {
                createTier3Options = new List<SelectOption>();
                createTier3Options.add(new SelectOption('--None--','--None--'));
                createTier3Options.add(new SelectOption('Apprenticeship School (Level 2/3/4/5)','Apprenticeship School (Level 2/3/4/5)'));
                createTier3Options.add(new SelectOption('Apprenticeship School (Level 6/7)','Apprenticeship School (Level 6/7)'));
                createTier3Options.add(new SelectOption('School of Business (Level 6/7)','School of Business (Level 6/7)'));
            } else if (tier2Options == 'Bespoke') {
                createTier3Options = new List<SelectOption>();
                createTier3Options.add(new SelectOption('--None--','--None--'));
            } else if (tier2Options == 'Public Non-Apps') {
                createTier3Options = new List<SelectOption>();
                createTier3Options.add(new SelectOption('--None--','--None--'));
                createTier3Options.add(new SelectOption('Apprenticeship School (Level 2/3/4/5)','Apprenticeship School (Level 2/3/4/5)'));
            }
        } else if (tier1Options == 'International') {
            if (tier2Options == 'Bespoke') {
                createTier3Options = new List<SelectOption>();
                createTier3Options.add(new SelectOption('--None--','--None--'));
                createTier3Options.add(new SelectOption('PD','PD'));
            } else if (tier2Options == 'Public Non-Apps') {
                createTier3Options = new List<SelectOption>();
                createTier3Options.add(new SelectOption('--None--','--None--'));
                createTier3Options.add(new SelectOption('Apprenticeship School (Level 2/3/4/5)','Apprenticeship School (Level 2/3/4/5)'));
                createTier3Options.add(new SelectOption('Channel Islands','Channel Islands'));
                createTier3Options.add(new SelectOption('Malaysia BPP','Malaysia BPP'));
                createTier3Options.add(new SelectOption('PD','PD'));
                createTier3Options.add(new SelectOption('Poland BPP','Poland BPP'));
                createTier3Options.add(new SelectOption('Romania BPP','Romania BPP'));
            }
        } else if (tier1Options == 'Law') {
            if (tier2Options == 'Apprenticeship') {
                createTier3Options = new List<SelectOption>();
                createTier3Options.add(new SelectOption('--None--','--None--'));
                createTier3Options.add(new SelectOption('Law School','Law School'));
            } else if (tier2Options == 'Public Non-Apps') {
                createTier3Options.add(new SelectOption('--None--','--None--'));
                createTier3Options.add(new SelectOption('Law School','Law School'));
                createTier3Options.add(new SelectOption('Malaysia BPP','Malaysia BPP'));
            }
        } else if (tier1Options == 'Other') {
            if (tier2Options == 'Apprenticeship' || tier2Options == 'Bespoke' || tier2Options == 'Other') {
                createTier3Options = new List<SelectOption>();
                createTier3Options.add(new SelectOption('--None--','--None--'));
            } else if (tier2Options == 'Public Non-Apps') {
                createTier3Options.add(new SelectOption('--None--','--None--'));
                createTier3Options.add(new SelectOption('Malaysia BPP','Malaysia BPP'));
            }
        } else if (tier1Options == 'Other Technology Products') {
            if (tier2Options == 'Accelerated Training') {
                createTier3Options = new List<SelectOption>();
                createTier3Options.add(new SelectOption('--None--','--None--'));
                createTier3Options.add(new SelectOption('Firebrand','Firebrand'));
            }
            if (tier2Options == 'Apprenticeship') {
                createTier3Options = new List<SelectOption>();
                createTier3Options.add(new SelectOption('--None--','--None--'));
                createTier3Options.add(new SelectOption('Apprenticeship School (Level 2/3/4/5)','Apprenticeship School (Level 2/3/4/5)'));
                createTier3Options.add(new SelectOption('Estio','Estio'));
                createTier3Options.add(new SelectOption('Firebrand','Firebrand'));
                createTier3Options.add(new SelectOption('School of Technology','School of Technology'));
            } else if (tier2Options == 'Bespoke') {
                createTier3Options = new List<SelectOption>();
                createTier3Options.add(new SelectOption('--None--','--None--'));
                createTier3Options.add(new SelectOption('Data Assembly','Data Assembly'));
                createTier3Options.add(new SelectOption('School of Technology','School of Technology'));
            } else if (tier2Options == 'Key Skills Series') {
                createTier3Options.add(new SelectOption('--None--','--None--'));
            } else if (tier2Options == 'Skills Bootcamps') {
                createTier3Options.add(new SelectOption('--None--','--None--'));
                createTier3Options.add(new SelectOption('Firebrand','Firebrand'));
            }
        } else if (tier1Options == 'Professional Development') {
            if (tier2Options == 'Bespoke'|| tier2Options == 'Key Skills Series') {
                createTier3Options = new List<SelectOption>();
                createTier3Options.add(new SelectOption('--None--','--None--'));
                createTier3Options.add(new SelectOption('PD','PD'));
            } else if (tier2Options == 'Public Non-Apps') {
                createTier3Options.add(new SelectOption('--None--','--None--'));
                createTier3Options.add(new SelectOption('Malaysia BPP','Malaysia BPP'));
                createTier3Options.add(new SelectOption('PD','PD'));
            }
        } else if (tier1Options == 'Risk / Compliance / Financial Crime') {
            if (tier2Options == 'Apprenticeship') {
                createTier3Options = new List<SelectOption>();
                createTier3Options.add(new SelectOption('--None--','--None--'));
                createTier3Options.add(new SelectOption('School of FS (Level 2/3/4/5)','School of FS (Level 2/3/4/5)'));
                createTier3Options.add(new SelectOption('School of FS (Level 6/7)','School of FS (Level 6/7)'));
            } else if (tier2Options == 'Bespoke') {
                createTier3Options = new List<SelectOption>();
                createTier3Options.add(new SelectOption('--None--','--None--'));
            } 
        } else if (tier1Options == 'UG / PG') {
            if (tier2Options == 'Bespoke') {
                createTier3Options = new List<SelectOption>();
                createTier3Options.add(new SelectOption('--None--','--None--'));
            } else if (tier2Options == 'Public Non-Apps') {
                createTier3Options = new List<SelectOption>();
                createTier3Options.add(new SelectOption('--None--','--None--'));
                createTier3Options.add(new SelectOption('Malaysia BPP','Malaysia BPP'));
                createTier3Options.add(new SelectOption('School of Business','School of Business'));
            }
        }
    }
    
    public void updateTier4Dropdown() {
        tier4Options = '';
        tier5Options = '';
        tier6Options = '';
        createTier4Options.clear();
        createTier5Options.clear();
        createTier6Options.clear();
        createTier5Options.add(new SelectOption('--None--','--None--'));
        createTier6Options.add(new SelectOption('--None--','--None--'));
        
        if (tier1Options == 'Accountancy and Tax') {
            if (tier2Options == 'Apprenticeship') {
                if (tier3Options == 'PQ') {
                    createTier4Options = new List<SelectOption>();
                    createTier4Options.add(new SelectOption('--None--','--None--'));
                    createTier4Options.add(new SelectOption('Accountancy / Taxation Professional - Level 7 (ACCA)','Accountancy / Taxation Professional - Level 7 (ACCA)'));
                    createTier4Options.add(new SelectOption('Accountancy / Taxation Professional - Level 7 (ATT/CTA)','Accountancy / Taxation Professional - Level 7 (ATT/CTA)'));
                    createTier4Options.add(new SelectOption('Accountancy / Taxation Professional - Level 7 (CIMA)','Accountancy / Taxation Professional - Level 7 (CIMA)'));
                    createTier4Options.add(new SelectOption('Accountancy / Taxation Professional - Level 7 (CTA)','Accountancy / Taxation Professional - Level 7 (CTA)'));
                    createTier4Options.add(new SelectOption('Accountancy / Taxation Professional - Level 7 (ICAEW ACA/CTA)','Accountancy / Taxation Professional - Level 7 (ICAEW ACA/CTA)'));
                    createTier4Options.add(new SelectOption('Accountancy / Taxation Professional - Level 7 (ICAEW)','Accountancy / Taxation Professional - Level 7 (ICAEW)'));
                    createTier4Options.add(new SelectOption('Advanced Diploma in Accounting - Level 3','Advanced Diploma in Accounting - Level 3'));
                    createTier4Options.add(new SelectOption('Assistant Accountant - Level 3','Assistant Accountant - Level 3'));
                    createTier4Options.add(new SelectOption('Foundation Certificate in Accounting - Level 2','Foundation Certificate in Accounting - Level 2'));
                    createTier4Options.add(new SelectOption('Junior Management Consultant - Level 4','Junior Management Consultant - Level 4'));
                    createTier4Options.add(new SelectOption('Professional Accounting / Taxation Technician - Level 4','Professional Accounting / Taxation Technician - Level 4'));
                    createTier4Options.add(new SelectOption('Professional Diploma in Accounting - Level 4 (AAT)','Professional Diploma in Accounting - Level 4 (AAT)'));
                    createTier4Options.add(new SelectOption('Professional Diploma in Accounting - Level 4 (ACCA)','Professional Diploma in Accounting - Level 4 (ACCA)'));
                    createTier4Options.add(new SelectOption('Professional Diploma in Accounting - Level 4 (ATT)','Professional Diploma in Accounting - Level 4 (ATT)'));
                    createTier4Options.add(new SelectOption('Professional Diploma in Accounting - Level 4 (CFAB)','Professional Diploma in Accounting - Level 4 (CFAB)'));
                    createTier4Options.add(new SelectOption('Professional Diploma in Accounting - Level 4 (CIMA)','Professional Diploma in Accounting - Level 4 (CIMA)'));
                    createTier4Options.add(new SelectOption('Professional Diploma in Accounting - Level 4 (ICAEW)','Professional Diploma in Accounting - Level 4 (ICAEW)'));
                } else if (tier3Options == 'Apprenticeship School (Level 2/3/4/5)') {
                    createTier4Options = new List<SelectOption>();
                    createTier4Options.add(new SelectOption('--None--','--None--'));
                    createTier4Options.add(new SelectOption('Accountancy (Scotland) – SCQF Level 5','Accountancy (Scotland) – SCQF Level 5'));
                    createTier4Options.add(new SelectOption('Accountancy (Scotland) – SCQF Level 6','Accountancy (Scotland) – SCQF Level 6'));
                    createTier4Options.add(new SelectOption('Accountancy (Scotland) – SCQF Level 8','Accountancy (Scotland) – SCQF Level 8'));
                }
            } else if (tier2Options == 'Bespoke') {
                createTier4Options = new List<SelectOption>();
                createTier4Options.add(new SelectOption('--None--','--None--'));
            } else if (tier2Options == 'Public Non-Apps') {
                if (tier3Options == 'Malaysia BPP') {
                    createTier4Options = new List<SelectOption>();
                    createTier4Options.add(new SelectOption('--None--','--None--'));
                } else if (tier3Options == 'PQ') {
                    createTier4Options = new List<SelectOption>();
                    createTier4Options.add(new SelectOption('--None--','--None--'));
                    createTier4Options.add(new SelectOption('AAT','AAT'));
                    createTier4Options.add(new SelectOption('ACCA','ACCA'));
                    createTier4Options.add(new SelectOption('ATT','ATT'));
                    createTier4Options.add(new SelectOption('CIMA','CIMA'));
                    createTier4Options.add(new SelectOption('CPA','CPA'));
                    createTier4Options.add(new SelectOption('CTA','CTA'));
                    createTier4Options.add(new SelectOption('FIA','FIA'));
                    createTier4Options.add(new SelectOption('ICAEW','ICAEW'));
                    createTier4Options.add(new SelectOption('ICAS','ICAS'));
                } 
            }
        } else if (tier1Options == 'Actuarial Education') {
            if (tier2Options == 'Apprenticeship') {
                if (tier3Options == 'ActEd') {
                    createTier4Options = new List<SelectOption>();
                    createTier4Options.add(new SelectOption('--None--','--None--'));
                    createTier4Options.add(new SelectOption('Actuarial Technician - Level 4','Actuarial Technician - Level 4'));
                    createTier4Options.add(new SelectOption('Actuary - Level 7','Actuary - Level 7'));
                }
            } else if (tier2Options == 'Public Non-Apps') {
                if (tier3Options == 'ActEd') {
                    createTier4Options = new List<SelectOption>();
                    createTier4Options.add(new SelectOption('--None--','--None--'));
                    createTier4Options.add(new SelectOption('Acturial Education','Acturial Education'));
                } else if (tier3Options == 'Malaysia BPP') {
                    createTier4Options = new List<SelectOption>();
                    createTier4Options.add(new SelectOption('--None--','--None--'));
                }
            }
        } else if (tier1Options == 'Banking / Insurance / FS') {
            if (tier2Options == 'Apprenticeship') {
                if (tier3Options == 'Apprenticeship School (Level 2/3/4/5)') {
                    createTier4Options = new List<SelectOption>();
                    createTier4Options.add(new SelectOption('--None--','--None--'));
                    createTier4Options.add(new SelectOption('Investment Operations Administrator - Level 2','Investment Operations Administrator - Level 2'));
                    createTier4Options.add(new SelectOption('Investment Operations Specialist - Level 4','Investment Operations Specialist - Level 4'));
                    createTier4Options.add(new SelectOption('Providing Financial Services (Scotland) – SCQF Level 5','Providing Financial Services (Scotland) – SCQF Level 5'));
                    createTier4Options.add(new SelectOption('Providing Financial Services (Scotland) – SCQF Level 6','Providing Financial Services (Scotland) – SCQF Level 6'));
                } else if (tier3Options == 'School of FS (Level 2/3/4/5)') {
                    createTier4Options = new List<SelectOption>();
                    createTier4Options.add(new SelectOption('--None--','--None--'));
                    createTier4Options.add(new SelectOption('Advanced Credit Controller / Debt Collection Specialist - Level 3','Advanced Credit Controller / Debt Collection Specialist - Level 3'));
                    createTier4Options.add(new SelectOption('Financial Services Customer Adviser - Level 2','Financial Services Customer Adviser - Level 2'));
                    createTier4Options.add(new SelectOption('Financial Services Administrator - Level 3','Financial Services Administrator - Level 3'));
                    createTier4Options.add(new SelectOption('Insurance Practitioner - Level 3','Insurance Practitioner - Level 3'));
                    createTier4Options.add(new SelectOption('Insurance Professional - Level 4','Insurance Professional - Level 4'));
                    createTier4Options.add(new SelectOption('Mortgage Adviser - Level 3','Mortgage Adviser - Level 3'));
                    createTier4Options.add(new SelectOption('Senior Financial Services Customer Adviser - Level 3','Senior Financial Services Customer Adviser - Level 3'));
                } else if (tier3Options == 'School of FS (Level 6/7)') {
                    createTier4Options = new List<SelectOption>();
                    createTier4Options.add(new SelectOption('--None--','--None--'));
                    createTier4Options.add(new SelectOption('Financial Services Professional - Level 6','Financial Services Professional - Level 6'));
                    createTier4Options.add(new SelectOption('Relationship Manager (Banking) - Level 6','Relationship Manager (Banking) - Level 6'));
                    createTier4Options.add(new SelectOption('Senior Insurance Professional - Level 6','Senior Insurance Professional - Level 6'));
                    createTier4Options.add(new SelectOption('Senior Investment / Commercial Banking Professional - Level 7','Senior Investment / Commercial Banking Professional - Level 7'));
                }
            } else if (tier2Options == 'Bespoke') {
                createTier4Options = new List<SelectOption>();
                createTier4Options.add(new SelectOption('--None--','--None--'));
            } else if (tier2Options == 'Public Non-Apps') {
                if (tier3Options == 'Malaysia BPP') {
                    createTier4Options = new List<SelectOption>();
                    createTier4Options.add(new SelectOption('--None--','--None--'));
                } else if (tier3Options == 'PQ') {
                    createTier4Options = new List<SelectOption>();
                    createTier4Options.add(new SelectOption('--None--','--None--'));
                    createTier4Options.add(new SelectOption('CFA Certificate in Climate and Investing','CFA Certificate in Climate and Investing'));
                    createTier4Options.add(new SelectOption('CFA Certificate in ESG Investing','CFA Certificate in ESG Investing'));
                } else if (tier3Options == 'PQ (FS)') {
                    createTier4Options = new List<SelectOption>();
                    createTier4Options.add(new SelectOption('--None--','--None--'));
                    createTier4Options.add(new SelectOption('Chartered Financial Analyst (CFA)','Chartered Financial Analyst (CFA)'));
                    createTier4Options.add(new SelectOption('Chartered Insurance institute (CII)','Chartered Insurance institute (CII)'));
                    createTier4Options.add(new SelectOption('CISI','CISI'));
                    createTier4Options.add(new SelectOption('Investment Management Certificate (IMC)','Investment Management Certificate (IMC)'));
                    createTier4Options.add(new SelectOption('IOC','IOC'));
                }
            }
        } else if (tier1Options == 'DTS / MSC in Data Analytics') {
            if (tier2Options == 'Apprenticeship') {
                if (tier3Options == 'School of Technology (Level 6/7)') {
                    createTier4Options = new List<SelectOption>();
                    createTier4Options.add(new SelectOption('--None--','--None--'));
                    createTier4Options.add(new SelectOption('Artificial Intelligence - Level 7','Artificial Intelligence - Level 7'));
                    createTier4Options.add(new SelectOption('BSc Digital and Technology Solutions - Level 6','BSc Digital and Technology Solutions - Level 6'));
                    createTier4Options.add(new SelectOption('Data Scientist - Level 6','Data Scientist - Level 6'));
                    createTier4Options.add(new SelectOption('MSc Applied Data Analytics','MSc Applied Data Analytics'));
                }
            } else if (tier2Options == 'Public Non-Apps') {
                if (tier3Options == 'Malaysia BPP') {
                    createTier4Options = new List<SelectOption>();
                    createTier4Options.add(new SelectOption('--None--','--None--'));
                } else if (tier3Options == 'School of Technology') {
                    createTier4Options = new List<SelectOption>();
                    createTier4Options.add(new SelectOption('--None--','--None--'));
                    createTier4Options.add(new SelectOption('MSc Applied Data Analytics','MSc Applied Data Analytics'));
                }
            }
        } else if (tier1Options == 'GDA / wrap') {
            if (tier2Options == 'Bespoke') {
                if (tier3Options == 'School of Business') {
                    createTier4Options = new List<SelectOption>();
                    createTier4Options.add(new SelectOption('--None--','--None--'));
                    createTier4Options.add(new SelectOption('Graduate Diploma in Accountancy','Graduate Diploma in Accountancy'));
                }
            } 
        } else if (tier1Options == 'Health') {
            if (tier2Options == 'Apprenticeship') {
                if (tier3Options == 'School of Nursing') {
                    createTier4Options = new List<SelectOption>();
                    createTier4Options.add(new SelectOption('--None--','--None--'));
                    createTier4Options.add(new SelectOption('Nursing Associate - Level 5','Nursing Associate - Level 5'));
                    createTier4Options.add(new SelectOption('Registered Nurse - degree (NMC 2018) - Level 6','Registered Nurse - degree (NMC 2018) - Level 6'));
                    createTier4Options.add(new SelectOption('Registered Nurse - degree (NMC 2018) - Level 6 RPeL','Registered Nurse - degree (NMC 2018) - Level 6 RPeL'));
                }
            } else if (tier2Options == 'Bespoke') {
                createTier4Options = new List<SelectOption>();
                createTier4Options.add(new SelectOption('--None--','--None--'));
            } else if (tier2Options == 'Public Non-Apps') {
                if (tier3Options == 'Malaysia BPP') {
                    createTier4Options = new List<SelectOption>();
                    createTier4Options.add(new SelectOption('--None--','--None--'));
                } else if (tier3Options == 'School of Health') {
                    createTier4Options = new List<SelectOption>();
                    createTier4Options.add(new SelectOption('--None--','--None--'));
                    createTier4Options.add(new SelectOption('Health School PD','Health School PD'));
                    createTier4Options.add(new SelectOption('Masters in Chiropractors','Masters in Chiropractors'));
                    createTier4Options.add(new SelectOption('Mentorship','Mentorship'));
                    createTier4Options.add(new SelectOption('MSc Healthcare Leadership','MSc Healthcare Leadership'));
                    createTier4Options.add(new SelectOption('MSc Psychology','MSc Psychology'));
                    createTier4Options.add(new SelectOption('Post Graduate Certificate in Health Service','Post Graduate Certificate in Health Service'));
                } else if (tier3Options == 'School of Nursing') {
                    createTier4Options = new List<SelectOption>();
                    createTier4Options.add(new SelectOption('--None--','--None--'));
                    createTier4Options.add(new SelectOption('BSc Nursing','BSc Nursing'));
                    createTier4Options.add(new SelectOption('Nursing Conversion','Nursing Conversion'));
                }
            }
        } else if (tier1Options == 'HR / Management / Business Admin') {
            if (tier2Options == 'Apprenticeship') {
                if (tier3Options == 'Apprenticeship School (Level 2/3/4/5)') {
                    createTier4Options = new List<SelectOption>();
                    createTier4Options.add(new SelectOption('--None--','--None--'));
                    createTier4Options.add(new SelectOption('Associate Project Manager - Level 4','Associate Project Manager - Level 4'));
                    createTier4Options.add(new SelectOption('Business Administration (Scotland) – SCQF Level 6','Business Administration (Scotland) – SCQF Level 6'));
                    createTier4Options.add(new SelectOption('Business Administrator - Level 3','Business Administrator - Level 3'));
                    createTier4Options.add(new SelectOption('Coaching Professional Level 5','Coaching Professional Level 5'));
                    createTier4Options.add(new SelectOption('HR Consultant / Partner - Level 5','HR Consultant / Partner - Level 5'));
                    createTier4Options.add(new SelectOption('HR Support - Level 3','HR Support - Level 3'));
                    createTier4Options.add(new SelectOption('Improvement Leader - Level 6','Improvement Leader - Level 6'));
                    createTier4Options.add(new SelectOption('Improvement Practitioner - Level 4','Improvement Practitioner - Level 4'));
                    createTier4Options.add(new SelectOption('Improvement Specialist - Level 5','Improvement Specialist - Level 5'));
                    createTier4Options.add(new SelectOption('Operations / Departmental Manager - Level 5','Operations / Departmental Manager - Level 5'));
                    createTier4Options.add(new SelectOption('Team Leader / Supervisor - Level 3','Team Leader / Supervisor - Level 3'));
                } else if (tier3Options == 'Apprenticeship School (Level 6/7)') {
                    createTier4Options = new List<SelectOption>();
                    createTier4Options.add(new SelectOption('--None--','--None--'));
                    createTier4Options.add(new SelectOption('Senior Leader - Level 7','Senior Leader - Level 7'));
                    createTier4Options.add(new SelectOption('Senior People Professional - Level 7','Senior People Professional - Level 7'));
                } else if (tier3Options == 'School of Business (Level 6/7)') {
                    createTier4Options = new List<SelectOption>();
                    createTier4Options.add(new SelectOption('--None--','--None--'));
                    createTier4Options.add(new SelectOption('Chartered Manager - Level 6','Chartered Manager - Level 6'));
                }
            } else if (tier2Options == 'Bespoke') {
                createTier4Options = new List<SelectOption>();
                createTier4Options.add(new SelectOption('--None--','--None--'));
            } else if (tier2Options == 'Public Non-Apps') {
                if (tier3Options == 'Apprenticeship School (Level 2/3/4/5)') {
                    createTier4Options = new List<SelectOption>();
                    createTier4Options.add(new SelectOption('--None--','--None--'));
                    createTier4Options.add(new SelectOption('Diploma in Professional Coaching','Diploma in Professional Coaching'));
                }
            } 
        } else if (tier1Options == 'International') {
            if (tier2Options == 'Bespoke') {
                if (tier3Options == 'PD') {
                    createTier4Options = new List<SelectOption>();
                    createTier4Options.add(new SelectOption('--None--','--None--'));
                    createTier4Options.add(new SelectOption('Accountancy & Tax','Accountancy & Tax'));
                    createTier4Options.add(new SelectOption('Data and Technology','Data and Technology'));
                    createTier4Options.add(new SelectOption('Exec Ed','Exec Ed'));
                    createTier4Options.add(new SelectOption('Finance for Non Finance','Finance for Non Finance'));
                    createTier4Options.add(new SelectOption('Financial Services','Financial Services'));
                    createTier4Options.add(new SelectOption('Higher Rights','Higher Rights'));
                    createTier4Options.add(new SelectOption('ICAS','ICAS'));
                    createTier4Options.add(new SelectOption('Insolvency','Insolvency'));
                    createTier4Options.add(new SelectOption('Law CPD','Law CPD'));
                    createTier4Options.add(new SelectOption('Law PSC','Law PSC'));
                    createTier4Options.add(new SelectOption('Management and Leadership','Management and Leadership'));
                    createTier4Options.add(new SelectOption('Memberships','Memberships'));
                    createTier4Options.add(new SelectOption('Personal Effectiveness','Personal Effectiveness'));
                }
            } else if (tier2Options == 'Public Non-Apps') {
                if (tier3Options == 'Apprenticeship School (Level 2/3/4/5)') {
                    createTier4Options = new List<SelectOption>();
                    createTier4Options.add(new SelectOption('--None--','--None--'));
                    createTier4Options.add(new SelectOption('Coaching relationships in practice','Coaching relationships in practice'));
                    createTier4Options.add(new SelectOption('Coaching within organisational environments','Coaching within organisational environments'));
                    createTier4Options.add(new SelectOption('Developing your coaching philosophy','Developing your coaching philosophy'));
                    createTier4Options.add(new SelectOption('Foundations of coaching and reflective practice','Foundations of coaching and reflective practice'));
                } else if (tier3Options == 'PD') {
                    createTier4Options = new List<SelectOption>();
                    createTier4Options.add(new SelectOption('--None--','--None--'));
                    createTier4Options.add(new SelectOption('Accountancy & Tax','Accountancy & Tax'));
                    createTier4Options.add(new SelectOption('Data and Technology','Data and Technology'));
                    createTier4Options.add(new SelectOption('Exec Ed','Exec Ed'));
                    createTier4Options.add(new SelectOption('Finance for Non Finance','Finance for Non Finance'));
                    createTier4Options.add(new SelectOption('Financial Services','Financial Services'));
                    createTier4Options.add(new SelectOption('Higher Rights','Higher Rights'));
                    createTier4Options.add(new SelectOption('ICAS','ICAS'));
                    createTier4Options.add(new SelectOption('Insolvency','Insolvency'));
                    createTier4Options.add(new SelectOption('Law CPD','Law CPD'));
                    createTier4Options.add(new SelectOption('Law PSC','Law PSC'));
                    createTier4Options.add(new SelectOption('Management and Leadership','Management and Leadership'));
                    createTier4Options.add(new SelectOption('Memberships','Memberships'));
                    createTier4Options.add(new SelectOption('Personal Effectiveness','Personal Effectiveness'));
                } else if (tier3Options == 'Romania BPP' || tier3Options == 'Poland BPP') {
                    createTier4Options = new List<SelectOption>();
                    createTier4Options.add(new SelectOption('--None--','--None--'));
                    createTier4Options.add(new SelectOption('PQ OCR Live','PQ OCR Live'));
                } else if (tier3Options == 'Channel Islands') {
                    createTier4Options = new List<SelectOption>();
                    createTier4Options.add(new SelectOption('--None--','--None--'));
                    createTier4Options.add(new SelectOption('FIA','FIA'));
                    createTier4Options.add(new SelectOption('ICSA','ICSA'));
                    createTier4Options.add(new SelectOption('ACCA','ACCA'));
                    createTier4Options.add(new SelectOption('Chartered Financial Analyst (CFA)','Chartered Financial Analyst (CFA)'));
                    createTier4Options.add(new SelectOption('CILT','CILT'));
                    createTier4Options.add(new SelectOption('CISI','CISI'));
                    createTier4Options.add(new SelectOption('ICAEW','ICAEW'));
                    createTier4Options.add(new SelectOption('PD','PD'));
                } else if (tier3Options == 'Malaysia BPP') {
                    createTier4Options = new List<SelectOption>();
                    createTier4Options.add(new SelectOption('--None--','--None--'));
                }
            }
        } else if (tier1Options == 'Law') {
            if (tier2Options == 'Apprenticeship') {
                if (tier3Options == 'Law School') {
                    createTier4Options = new List<SelectOption>();
                    createTier4Options.add(new SelectOption('--None--','--None--'));
                    createTier4Options.add(new SelectOption('Graduate Diploma in Legal Practice (Day release Graduate Solicitor) - Level 7','Graduate Diploma in Legal Practice (Day release Graduate Solicitor) - Level 7'));
                    createTier4Options.add(new SelectOption('Paralegal - Level 3','Paralegal - Level 3'));
                    createTier4Options.add(new SelectOption('Postgraduate Diploma in Legal Practice (Block teach Graduate Solicitor) - Level 7','Postgraduate Diploma in Legal Practice (Block teach Graduate Solicitor) - Level 7'));
                    createTier4Options.add(new SelectOption('Solicitor - Level 7','Solicitor - Level 7'));
                    createTier4Options.add(new SelectOption('Solicitor [with exemptions] - Level 7','Solicitor [with exemptions] - Level 7'));
                }
            } else if (tier2Options == 'Public Non-Apps') {
                if (tier3Options == 'Law School') {
                    createTier4Options = new List<SelectOption>();
                    createTier4Options.add(new SelectOption('--None--','--None--'));
                    createTier4Options.add(new SelectOption('Academic LLMs','Academic LLMs'));
                    createTier4Options.add(new SelectOption('BTC','BTC'));
                    createTier4Options.add(new SelectOption('LPC','LPC'));
                    createTier4Options.add(new SelectOption('pGDL','pGDL'));
                    createTier4Options.add(new SelectOption('STC','STC'));
                } else if (tier3Options == 'Malaysia BPP') {
                    createTier4Options = new List<SelectOption>();
                    createTier4Options.add(new SelectOption('--None--','--None--'));
                }
            }
        } else if (tier1Options == 'Other') {
            if (tier2Options == 'Apprenticeship') {
                createTier4Options = new List<SelectOption>();
                createTier4Options.add(new SelectOption('--None--','--None--'));
            } else if (tier2Options == 'Bespoke') {
                createTier4Options = new List<SelectOption>();
                createTier4Options.add(new SelectOption('--None--','--None--'));
            } else if (tier2Options == 'Other') {
                createTier4Options = new List<SelectOption>();
                createTier4Options.add(new SelectOption('--None--','--None--'));
            } else if (tier2Options == 'Public Non-Apps') {
                createTier4Options = new List<SelectOption>();
                createTier4Options.add(new SelectOption('--None--','--None--'));
            }
        } else if (tier1Options == 'Other Technology Products') {
            if (tier2Options == 'Accelerated Training') {
                if (tier3Options == 'Firebrand') {
                    createTier4Options = new List<SelectOption>();
                    createTier4Options.add(new SelectOption('--None--','--None--'));
                    createTier4Options.add(new SelectOption('App and Web Development','App and Web Development'));
                    createTier4Options.add(new SelectOption('Cloud Computing Certifications','Cloud Computing Certifications'));
                    createTier4Options.add(new SelectOption('Cyber Crime','Cyber Crime'));
                    createTier4Options.add(new SelectOption('Cyber Security','Cyber Security'));
                    createTier4Options.add(new SelectOption('Data Protection','Data Protection'));
                    createTier4Options.add(new SelectOption('Data, AI and Machine Learning Certifications','Data, AI and Machine Learning Certifications'));
                    createTier4Options.add(new SelectOption('Project Management Training','Project Management Training'));
                    createTier4Options.add(new SelectOption('Software Testing','Software Testing'));
                }
            } else if (tier2Options == 'Apprenticeship') {
                if (tier3Options == 'Apprenticeship School (Level 2/3/4/5)') {
                    createTier4Options = new List<SelectOption>();
                    createTier4Options.add(new SelectOption('--None--','--None--'));
                    createTier4Options.add(new SelectOption('IT Professional (Scotland) – SCQF Level 6','IT Professional (Scotland) – SCQF Level 6'));
                    createTier4Options.add(new SelectOption('IT Professional (Scotland) – SCQF Level 8','IT Professional (Scotland) – SCQF Level 8'));
                } else if (tier3Options == 'Estio') {
                    createTier4Options = new List<SelectOption>();
                    createTier4Options.add(new SelectOption('--None--','--None--'));
                    createTier4Options.add(new SelectOption('Application Support Lead - Level 4','Application Support Lead - Level 4'));
                    createTier4Options.add(new SelectOption('Business Analyst - Level 4','Business Analyst - Level 4'));
                    createTier4Options.add(new SelectOption('Content Creator - Level 3','Content Creator - Level 3'));
                    createTier4Options.add(new SelectOption('Cyber Security Technologist - Level 4','Cyber Security Technologist - Level 4'));
                    createTier4Options.add(new SelectOption('Data Analyst - Level 4','Data Analyst - Level 4'));
                    createTier4Options.add(new SelectOption('Data Technician - Level 3','Data Technician - Level 3'));
                    createTier4Options.add(new SelectOption('DevOps Engineer - Level 4','DevOps Engineer - Level 4'));
                    createTier4Options.add(new SelectOption('Digital Marketer - Level 3','Digital Marketer - Level 3'));
                    createTier4Options.add(new SelectOption('Digital Support Technician - Level 3','Digital Support Technician - Level 3'));
                    createTier4Options.add(new SelectOption('Information Communication Technician - Level 3','Information Communication Technician - Level 3'));
                    createTier4Options.add(new SelectOption('Infrastructure Technician - Level 3','Infrastructure Technician - Level 3'));
                    createTier4Options.add(new SelectOption('IT Solutions Technician - Level 3','IT Solutions Technician - Level 3'));
                    createTier4Options.add(new SelectOption('Network Engineer - Level 4','Network Engineer - Level 4'));
                    createTier4Options.add(new SelectOption('Radio Network Technician - Level 3','Radio Network Technician - Level 3'));
                    createTier4Options.add(new SelectOption('Software Developer - Level 4','Software Developer - Level 4'));
                    createTier4Options.add(new SelectOption('Software Development Technician - Level 3','Software Development Technician - Level 3'));
                    createTier4Options.add(new SelectOption('Software Tester - Level 4','Software Tester - Level 4'));
                    createTier4Options.add(new SelectOption('Telecomms Field Operative - Level 2','Telecomms Field Operative - Level 2'));
                } else if (tier3Options == 'Firebrand') {
                    createTier4Options = new List<SelectOption>();
                    createTier4Options.add(new SelectOption('--None--','--None--'));
                    createTier4Options.add(new SelectOption('Cyber Security Technician - Level 3','Cyber Security Technician - Level 3'));
                    createTier4Options.add(new SelectOption('Data Technician - Level 3','Data Technician - Level 3'));
                    createTier4Options.add(new SelectOption('DevOps Engineer - Level 4','DevOps Engineer - Level 4'));
                    createTier4Options.add(new SelectOption('Digital Marketer - Level 3','Digital Marketer - Level 3'));
                    createTier4Options.add(new SelectOption('Digital Support Technician - Level 3','Digital Support Technician - Level 3'));
                    createTier4Options.add(new SelectOption('IT Solutions Technician - Level 3','IT Solutions Technician - Level 3'));
                    createTier4Options.add(new SelectOption('IT Technical Salesperson - Level 3','IT Technical Salesperson - Level 3'));
                    createTier4Options.add(new SelectOption('Information Communication Technician - Level 3','Information Communication Technician - Level 3'));
                    createTier4Options.add(new SelectOption('Network Engineer - Level 4','Network Engineer - Level 4'));
                    createTier4Options.add(new SelectOption('Software Developer - Level 4','Software Developer - Level 4'));
                    createTier4Options.add(new SelectOption('Software Development Technician - Level 3','Software Development Technician - Level 3'));
                    createTier4Options.add(new SelectOption('Software Tester - Level 4','Software Tester - Level 4'));
                } else if (tier3Options == 'School of Technology') {
                    createTier4Options = new List<SelectOption>();
                    createTier4Options.add(new SelectOption('--None--','--None--'));
                    createTier4Options.add(new SelectOption('Business Analyst - Level 4','Business Analyst - Level 4'));
                    createTier4Options.add(new SelectOption('Data Analyst - Level 4','Data Analyst - Level 4'));
                    createTier4Options.add(new SelectOption('Data Engineering - Level 5','Data Engineering - Level 5'));
                    createTier4Options.add(new SelectOption('Data Technician - Level 3','Data Technician - Level 3'));
                    createTier4Options.add(new SelectOption('Software Developer - Level 4','Software Developer - Level 4'));
                }
            } else if (tier2Options == 'Bespoke') {
                if (tier3Options == 'Data Assembly') {
                    createTier4Options = new List<SelectOption>();
                    createTier4Options.add(new SelectOption('--None--','--None--'));
                } else if (tier3Options == 'School of Technology') {
                    createTier4Options = new List<SelectOption>();
                    createTier4Options.add(new SelectOption('--None--','--None--'));
                    createTier4Options.add(new SelectOption('Digital Accountant','Digital Accountant'));
                    createTier4Options.add(new SelectOption('Digital Skills for Professional Services','Digital Skills for Professional Services'));
                    createTier4Options.add(new SelectOption('MSc Data Professional (MSc Top-Up)','MSc Data Professional (MSc Top-Up)'));
                }
            } else if (tier2Options == 'Skills Bootcamps') {
                if (tier3Options == 'Firebrand') {
                    createTier4Options = new List<SelectOption>();
                    createTier4Options.add(new SelectOption('--None--','--None--'));
                    createTier4Options.add(new SelectOption('Central Business Services','Central Business Services'));
                    createTier4Options.add(new SelectOption('Data','Data'));
                    createTier4Options.add(new SelectOption('Infrastructure & Security','Infrastructure & Security'));
                    createTier4Options.add(new SelectOption('Software Engineering','Software Engineering'));
                }
            }
        } else if (tier1Options == 'Professional Development') {
            if (tier2Options == 'Bespoke') {
                if (tier3Options == 'PD') {
                    createTier4Options = new List<SelectOption>();
                    createTier4Options.add(new SelectOption('--None--','--None--'));
                    createTier4Options.add(new SelectOption('Accountancy & Tax','Accountancy & Tax'));
                    createTier4Options.add(new SelectOption('Data and Technology','Data and Technology'));
                    createTier4Options.add(new SelectOption('Exec Ed','Exec Ed'));
                    createTier4Options.add(new SelectOption('Finance for Non Finance','Finance for Non Finance'));
                    createTier4Options.add(new SelectOption('Financial Services','Financial Services'));
                    createTier4Options.add(new SelectOption('Higher Rights','Higher Rights'));
                    createTier4Options.add(new SelectOption('ICAS','ICAS'));
                    createTier4Options.add(new SelectOption('Insolvency','Insolvency'));
                    createTier4Options.add(new SelectOption('Law CPD','Law CPD'));
                    createTier4Options.add(new SelectOption('Law PSC','Law PSC'));
                    createTier4Options.add(new SelectOption('Management and Leadership','Management and Leadership'));
                    createTier4Options.add(new SelectOption('Memberships','Memberships'));
                    createTier4Options.add(new SelectOption('Personal Effectiveness','Personal Effectiveness'));
                }
            } else if (tier2Options == 'Public Non-Apps') {
                if (tier3Options == 'Malaysia BPP') {
                    createTier4Options = new List<SelectOption>();
                    createTier4Options.add(new SelectOption('--None--','--None--'));
                } else if (tier3Options == 'PD') {
                    createTier4Options = new List<SelectOption>();
                    createTier4Options.add(new SelectOption('--None--','--None--'));
                    createTier4Options.add(new SelectOption('Accountancy & Tax','Accountancy & Tax'));
                    createTier4Options.add(new SelectOption('Data and Technology','Data and Technology'));
                    createTier4Options.add(new SelectOption('Exec Ed','Exec Ed'));
                    createTier4Options.add(new SelectOption('Finance for Non Finance','Finance for Non Finance'));
                    createTier4Options.add(new SelectOption('Financial Services','Financial Services'));
                    createTier4Options.add(new SelectOption('Higher Rights','Higher Rights'));
                    createTier4Options.add(new SelectOption('ICAS','ICAS'));
                    createTier4Options.add(new SelectOption('Insolvency','Insolvency'));
                    createTier4Options.add(new SelectOption('Law CPD','Law CPD'));
                    createTier4Options.add(new SelectOption('Law PSC','Law PSC'));
                    createTier4Options.add(new SelectOption('Management and Leadership','Management and Leadership'));
                    createTier4Options.add(new SelectOption('Memberships','Memberships'));
                    createTier4Options.add(new SelectOption('Personal Effectiveness','Personal Effectiveness'));
                }
            } else if (tier2Options == 'Key Skills Series') {
                if (tier3Options == 'PD') {
                    createTier4Options = new List<SelectOption>();
                    createTier4Options.add(new SelectOption('--None--','--None--'));
                    createTier4Options.add(new SelectOption('Agile Thinking in a Changing Business World','Agile Thinking in a Changing Business World'));
                    createTier4Options.add(new SelectOption('Analytical and Critical Thinking','Analytical and Critical Thinking'));
                    createTier4Options.add(new SelectOption('Building Effective Coaching Skills','Building Effective Coaching Skills'));
                    createTier4Options.add(new SelectOption('Creating a Customer-Centric Organisation','Creating a Customer-Centric Organisation'));
                    createTier4Options.add(new SelectOption('Data Fundamentals','Data Fundamentals'));
                    createTier4Options.add(new SelectOption('Data Visualisation','Data Visualisation'));
                    createTier4Options.add(new SelectOption('Digital Transformation','Digital Transformation'));
                    createTier4Options.add(new SelectOption('Emotional Intelligence','Emotional Intelligence'));
                    createTier4Options.add(new SelectOption('Leading in a Changing Business Environment','Leading in a Changing Business Environment'));
                    createTier4Options.add(new SelectOption('Resilience and Mental Health','Resilience and Mental Health'));
                    createTier4Options.add(new SelectOption('Teamwork for a Connected World','Teamwork for a Connected World'));
                    createTier4Options.add(new SelectOption('Using Data for Decision Making','Using Data for Decision Making')); 
                }
            }
        } else if (tier1Options == 'Risk / Compliance / Financial Crime') {
            if (tier2Options == 'Apprenticeship') {
                if (tier3Options == 'School of FS (Level 2/3/4/5)') {
                    createTier4Options = new List<SelectOption>();
                    createTier4Options.add(new SelectOption('--None--','--None--'));
                    createTier4Options.add(new SelectOption('Compliance / Risk Officer - Level 3','Compliance / Risk Officer - Level 3'));
                } else if (tier3Options == 'School of FS (Level 6/7)') {
                    createTier4Options = new List<SelectOption>();
                    createTier4Options.add(new SelectOption('--None--','--None--'));
                    createTier4Options.add(new SelectOption('Senior Compliance / Risk Specialist - Level 6','Senior Compliance / Risk Specialist - Level 6'));
                }
            } else if (tier2Options == 'Bespoke') {
                createTier4Options = new List<SelectOption>();
                createTier4Options.add(new SelectOption('--None--','--None--'));
            }
        } else if (tier1Options == 'UG / PG') {
            if (tier2Options == 'Bespoke') {
                createTier4Options = new List<SelectOption>();
                createTier4Options.add(new SelectOption('--None--','--None--'));
            } else if (tier2Options == 'Public Non-Apps') {
                if (tier3Options == 'Malaysia BPP') {
                    createTier4Options = new List<SelectOption>();
                    createTier4Options.add(new SelectOption('--None--','--None--'));
                } else if (tier3Options == 'School of Business') {
                    createTier4Options = new List<SelectOption>();
                    createTier4Options.add(new SelectOption('--None--','--None--'));
                    createTier4Options.add(new SelectOption('Academic and careers skills','Academic and careers skills'));
                    createTier4Options.add(new SelectOption('ACCA Professional Level','ACCA Professional Level'));
                    createTier4Options.add(new SelectOption('Advanced Diploma in Accounting Finance (ACCA Route)','Advanced Diploma in Accounting Finance (ACCA Route)'));
                    createTier4Options.add(new SelectOption('BSc Accounting and Finance','BSc Accounting and Finance'));
                    createTier4Options.add(new SelectOption('MSc Accounting and Finance (Advanced Diploma Route)','MSc Accounting and Finance (Advanced Diploma Route)'));
                    createTier4Options.add(new SelectOption('MSc Management','MSc Management'));
                }
            }
        } else {
            createTier3Options = new List<SelectOption>();
            createTier3Options.add(new SelectOption('--None--','--None--'));
            createTier4Options = new List<SelectOption>();
            createTier4Options.add(new SelectOption('--None--','--None--'));
        }
    }
    
    public void updateTier5Dropdown() {
        tier5Options = '';
        tier6Options = '';
        createTier5Options.clear();
        createTier6Options.clear();
        createTier6Options.add(new SelectOption('--None--','--None--'));
        
        createTier5Options = new List<SelectOption>();
        if (tier1Options == 'Professional Development') {
            createTier5Options.add(new SelectOption('--None--','--None--'));
            createTier5Options.add(new SelectOption('Blended','Blended'));
            createTier5Options.add(new SelectOption('Face to Face','Face to Face'));
            createTier5Options.add(new SelectOption('Online Classroom Live','Online Classroom Live'));
            createTier5Options.add(new SelectOption('Online Demand','Online Demand'));
        }
        
        if (tier2Options == 'Apprenticeship') {
            createTier5Options.add(new SelectOption('--None--','--None--'));
            createTier5Options.add(new SelectOption('Existing Staff','Existing Staff'));
            createTier5Options.add(new SelectOption('Traineeships','Traineeships'));
            createTier5Options.add(new SelectOption('School Leavers','School Leavers'));
            createTier5Options.add(new SelectOption('Graduates','Graduates'));
            createTier5Options.add(new SelectOption('Mixed Recruitment Type','Mixed Recruitment Type'));
        }
        
        if (createTier5Options.isEmpty()) {
            createTier5Options.add(new SelectOption('--None--','--None--'));
        }
    }
    
    public void updateTier6Dropdown() {
        tier6Options = '';
        createTier6Options.clear();
        
        createTier6Options = new List<SelectOption>();
        if (tier2Options == 'Apprenticeship') {
            createTier6Options.add(new SelectOption('--None--','--None--'));
            createTier6Options.add(new SelectOption('Existing Employee','Existing Employee'));
            createTier6Options.add(new SelectOption('New Recruit (BPP RS)','New Recruit (BPP RS)'));
            createTier6Options.add(new SelectOption('New Recruit (Estio RS)','New Recruit (Estio RS)'));
            createTier6Options.add(new SelectOption('New Recruit (in house)','New Recruit (in house)'));
        }
        
        if (createTier6Options.isEmpty()) {
            createTier6Options.add(new SelectOption('--None--','--None--'));
        }
    }
    
    public List<SelectOption> getNewTier2Options() {
        return createTier2Options;
    }
    
    public List<SelectOption> getNewTier3Options() {
        return createTier3Options;
    }
    
    public List<SelectOption> getNewTier4Options() {
        return createTier4Options;
    }
    
    public List<SelectOption> getNewTier5Options() {
        return createTier5Options;
    }
    
    public List<SelectOption> getNewTier6Options() {
        return createTier6Options;
    }
}